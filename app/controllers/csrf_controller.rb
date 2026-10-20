class CsrfController < ApplicationController
  # INTENCIONALMENTE VULNERÁVEL APENAS NESTE CONTROLADOR:
  # desabilita o token CSRF para demonstrar o impacto em ambiente local.
  skip_forgery_protection

  def show
    @balance = LabAccount.first_or_create!(name: "Conta de demonstração", balance: 100)
  end

  def transfer
    @account = LabAccount.first_or_create!(name: "Conta de demonstração", balance: 100)
    amount = params[:amount].to_i
    if amount.positive? && amount <= @account.balance
      @account.update!(balance: @account.balance - amount)
      flash[:notice] = "Ação executada: saldo reduzido em #{amount} créditos fictícios."
    else
      flash[:alert] = "Valor inválido ou saldo insuficiente."
    end
    redirect_to "/csrf"
  end
end
