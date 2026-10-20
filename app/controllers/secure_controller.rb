class SecureController < ApplicationController
  def index
    @comments = Comment.order(created_at: :desc)
  end

  # Rails escapa texto por padrão; não usar raw/html_safe em entrada não confiável.
  def create_comment
    Comment.create!(body: params[:body].to_s)
    redirect_to "/secure", notice: "Comentário salvo com escape HTML padrão do Rails."
  end

  def users
    term = params[:q].to_s
    # Consulta parametrizada: a entrada é tratada como dado, não como SQL.
    @users = LabUser.where("username = ?", term)
  end
end
