module QuizHelper
  def quiz_choice_label(choice)
    case choice
    when "edible"
      "食用"
    when "poisonous"
      "毒きのこ"
    else
      "未回答"
    end
  end

  def quiz_badge(correct)
    if correct == true
      content_tag(:span, "正解！", class: "badge badge--correct")
    elsif correct == false
      content_tag(:span, "残念！ 正解は「食用」", class: "badge badge--incorrect")
    else
      content_tag(:span, "未回答", class: "badge badge--neutral")
    end
  end
end
