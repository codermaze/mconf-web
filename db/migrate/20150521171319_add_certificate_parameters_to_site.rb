class AddCertificateParametersToSite < ActiveRecord::Migration
  def change
    add_column :sites, :certificate_login_enabled, :boolean
    add_column :sites, :certificate_id_field, :string
  end
end
