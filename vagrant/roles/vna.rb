run_list(%w(
recipe[vnet::vna]
))

override_attributes(
  { docker: { version: "0.9.0-3.el6" } }
)
