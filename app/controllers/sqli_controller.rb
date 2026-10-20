class SqliController < ApplicationController
  def index
  end

  def search
    term = params[:q].to_s
    # INTENCIONALMENTE VULNERÁVEL: concatenação de entrada na string SQL.
    # Não utilizar este padrão em aplicações reais.
    @sql_preview = "SELECT id, username, role FROM lab_users WHERE username = '#{term}'"
    @users = LabUser.find_by_sql(@sql_preview)
    render :results
  rescue ActiveRecord::StatementInvalid => e
    @error = e.message
    render :results, status: :bad_request
  end
end
