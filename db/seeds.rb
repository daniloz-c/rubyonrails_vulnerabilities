LabUser.find_or_create_by!(username: "alice") { |u| u.role = "user" }
LabUser.find_or_create_by!(username: "bob") { |u| u.role = "admin" }
LabUser.find_or_create_by!(username: "carol") { |u| u.role = "user" }
LabAccount.first_or_create!(name: "Conta de demonstração", balance: 100)
