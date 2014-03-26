run_list(%w(
recipe[vnet_vna]
))

override_attributes(
  vnet_vna: { docker: { cleanup: true } }
)
