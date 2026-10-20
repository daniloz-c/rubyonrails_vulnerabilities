Rails.application.routes.draw do
  root "home#index"

  get  "/xss",             to: "xss#index"
  post "/xss/comments",    to: "xss#create"
  post "/xss/reflected",   to: "xss#reflected"

  get  "/csrf",            to: "csrf#show"
  post "/csrf/transfer",   to: "csrf#transfer"

  get  "/sqli",            to: "sqli#index"
  get  "/sqli/search",     to: "sqli#search"

  get  "/secure",          to: "secure#index"
  post "/secure/comments", to: "secure#create_comment"
  get  "/secure/users",    to: "secure#users"
end
