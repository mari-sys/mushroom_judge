class QuizController < ApplicationController
  QUESTIONS = [
    # --- 食用（秋が旬・野生寄り） ---
    { key: :matsutake,      name: "マツタケ",        description: "秋の王者。芳香が命。土瓶蒸しや炭焼きで。",                   image_path: "quiz/matsutake.png",        edible: true  },
    { key: :maitake,        name: "マイタケ",        description: "秋に群生。香りと食感が良く天ぷらが人気。",                       image_path: "quiz/maitake.png",          edible: true  },
    { key: :nameko,         name: "ナメコ",          description: "晩秋に発生。ぬめりが楽しい味噌汁の定番。",                       image_path: "quiz/nameko.png",           edible: true  },
    { key: :honshimeji,     name: "ホンシメジ",      description: "“香り松茸、味しめじ”の本家。秋の旨みが濃い。",                   image_path: "quiz/honshimeji.png",       edible: true  },
    { key: :hatakeshimeji,  name: "ハタケシメジ",    description: "畑や道端にも。だしが出て万能、秋の常連。",                         image_path: "quiz/hatakeshimeji.png",    edible: true  },
    { key: :yamabushitake,  name: "ヤマブシタケ",    description: "白いポンポン状。秋に発生、出汁と食感がユニーク。",                 image_path: "quiz/yamabushitake.png",    edible: true  },
    { key: :hanaiguchi,     name: "ハナイグチ（リコボウ）", description: "カラマツ林に多い秋の味覚。ぬめりとコリコリ感。",         image_path: "quiz/hanaiguchi.png",       edible: true  },
    { key: :kurokawa,       name: "クロカワ",        description: "渋みが特徴の通好み。秋の山の味、網焼きや煮物に。",                 image_path: "quiz/kurokawa.png",         edible: true  },
    { key: :murasakishimeji, name: "ムラサキシメジ",  description: "晩秋〜初冬。美しい紫色、火を通すとまろやか。",                   image_path: "quiz/murasakishimeji.png",  edible: true  },

    # --- 毒（秋に出会いがち・要注意） ---
    { key: :destroying_angel, name: "ドクツルタケ",   description: "猛毒。純白で美しいが致命的。秋にも発生。",                     image_path: "quiz/dokutsurutake.png",    edible: false },
    { key: :death_cap,        name: "タマゴテングタケ", description: "“猛毒御三家”。卵殻のようなツボが目印。",                     image_path: "quiz/tamagotengudake.png",  edible: false },
    { key: :fly_agaric,       name: "ベニテングタケ", description: "赤い傘に白い斑点。派手だが毒性あり。秋の象徴。",               image_path: "quiz/benitengudake.png",    edible: false },
    { key: :tsukiyotake,      name: "ツキヨタケ",     description: "暗所で弱く光る。食中毒多発、ヒラタケ類と誤認注意。",             image_path: "quiz/tsukiyotake.png",      edible: false },
    { key: :kusaurabenitake,  name: "クサウラベニタケ", description: "食用キノコと誤認されがち。秋の中毒常連。",                   image_path: "quiz/kusaurabenitake.png",  edible: false },
    { key: :nigakuritake,     name: "ニガクリタケ",   description: "猛毒。クリタケ（食用）と混同しやすく超危険。",                 image_path: "quiz/nigakuritake.png",     edible: false }
  ]
  .freeze

  # 1回のクイズで出す問題数
  NUM_QUESTIONS = 10

  TITLES = [
    { threshold: 10, name: "きのこもりの長🦉" },
    { threshold: 7,  name: "きのこのおともだち🐿" },
    { threshold: 4,  name: "ちびきのこ🍄" },
    { threshold: 0,  name: "ねむねむ胞子💤" }
  ].freeze

  helper_method :question_count

  # クイズ開始
  def index
    reset_quiz_state
  end

  # 出題（画像のみ表示）
  def show
    ensure_quiz_state!
    @question_number     = extract_question_number
    q                    = question_for(@question_number)
    @question_image_path = q[:image_path]
  end

  # 回答
  def answer
    Rails.logger.debug "[QUIZ] params=#{params.inspect}"
    ensure_quiz_state!
    question_number = extract_question_number
    choice = params[:choice] # "edible" or "poisonous"

    unless %w[edible poisonous].include?(choice)
      redirect_to quiz_question_path(number: question_number), alert: "回答を選択してください。"
      return
    end

    store_answer(question_number, choice)

    if question_number >= question_count
      redirect_to quiz_result_path
    else
      redirect_to quiz_question_path(number: question_number + 1)
    end
  end

  # 結果
  def result
    ensure_quiz_state!
    answers = session[:quiz_state]["answers"] # キーは q_idx（= QUESTIONS のインデックス）

    # スコア集計（保存形式に依存しない）
    @score = answers.values.count { |a| a["correct"] }
    @title = TITLES.find { |t| @score >= t[:threshold] }[:name]

    # 出題順に沿って復元（q_idx をキーに answers 参照）
    order = session[:quiz_state]["order"] || limited_order
    @question_results = order.each_with_index.map do |q_idx, i|
      question = QUESTIONS[q_idx]
      stored   = answers[q_idx.to_s]   # ←★ ここを文字列キーに
      {
        number: i + 1,
        question: {
          name:        question[:name],
          description: question[:description],
          image_path:  question[:image_path],
          edible:      question[:edible]
        },
        choice:  stored&.dig("choice"),   # "edible"/"poisonous" or nil
        correct: stored&.dig("correct")   # true/false or nil
      }
    end
  end

  private

  # 現在の「何問目か」を正規化して返す（1始まり）
  def extract_question_number
    number = params[:number].presence || session[:quiz_state]["current_question"] || 1
    number = number.to_i
    number = 1 if number < 1
    number = question_count if number > question_count
    session[:quiz_state]["current_question"] = number
    number
  end

  # N問目の実問題（QUESTIONS 内の要素）を取得
  def question_for(number)
    order = session[:quiz_state]["order"] || limited_order
    QUESTIONS[order[number - 1]]
  end

  # ★ 修正：回答は「出題された実問題のインデックス(q_idx)」で保存する
  def store_answer(number, choice)
    answers = session[:quiz_state]["answers"]
    order   = session[:quiz_state]["order"] || limited_order
    q_idx   = order[number - 1]                     # 実問題のインデックス
    q       = QUESTIONS[q_idx]
    user_thinks_edible = (choice == "edible")
    correct = (user_thinks_edible == q[:edible])
    q_key = q_idx.to_s
    answers[q_idx] = { "choice" => choice, "correct" => correct }  # ★ キーは q_idx
    session[:quiz_state]["answers"] = answers
  end

  # クイズ状態（ランダム順含む）を初期化
  def reset_quiz_state
    session[:quiz_state] = {
      "answers" => {},             # キー: q_idx
      "current_question" => 1,
      "order" => limited_order     # ★ ここで NUM_QUESTIONS 件に絞って保存
    }
  end

  def ensure_quiz_state!
    session[:quiz_state] ||= {
      "answers" => {},
      "current_question" => 1,
      "order" => limited_order
    }
  end

  # 全問題のインデックス配列
  def default_order
    (0...QUESTIONS.size).to_a
  end

  # NUM_QUESTIONS 件だけランダム抽出した順序
  def limited_order
    default_order.sample([ NUM_QUESTIONS, QUESTIONS.size ].min)
  end

  # 今回のセッションでの問題数
  def question_count
    (session[:quiz_state] && session[:quiz_state]["order"]&.length) || [ NUM_QUESTIONS, QUESTIONS.size ].min
  end
end
