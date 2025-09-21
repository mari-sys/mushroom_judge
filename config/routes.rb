Rails.application.routes.draw do
  root 'quiz#index'

  get 'quiz', to: 'quiz#index', as: :quiz
  get 'quiz/question/:number', to: 'quiz#show', as: :quiz_question
  post 'quiz/answer', to: 'quiz#answer', as: :quiz_answer
  get 'quiz/result', to: 'quiz#result', as: :quiz_result

end
