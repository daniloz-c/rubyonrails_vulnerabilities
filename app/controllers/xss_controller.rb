class XssController < ApplicationController
  def index
    @comments = Comment.order(created_at: :desc)
  end

  # INTENCIONALMENTE VULNERÁVEL: o template usa raw() no conteúdo do comentário.
  def create
    Comment.create!(body: params[:body].to_s)
    redirect_to "/xss", notice: "Comentário salvo no laboratório."
  end

  # INTENCIONALMENTE VULNERÁVEL: o template imprime a entrada como HTML.
  def reflected
    @message = params[:message].to_s
    render :reflected
  end
end
