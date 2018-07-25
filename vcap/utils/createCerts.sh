#! /bin/bash

# certPath=/etc/pki/tls/private
certPath=testdata
root_key="${certPath}"/root.key
root_csr="${certPath}"/root.csr
root_cert="${certPath}"/root.crt
client_csr="${certPath}"/client.csr
client_cert="${certPath}"/client.crt
client_key="${certPath}"/client.key
server_csr="${certPath}"/server.csr
server_cert="${certPath}"/server.crt
server_key="${certPath}"/server.key

# create a certificate authority valid for 10 years
openssl req -new -nodes -text -out "${root_csr}" -keyout "${root_key}" -subj /CN=lm2
openssl x509 -req -in "${root_csr}" -text -days 3650 -extfile /etc/pki/tls/openssl.cnf -extensions v3_ca -signkey "${root_key}" -out "${root_cert}"

# create a 10-year grpc server key pair signed by the above ca
openssl req -new -nodes -text -out "${server_csr}" -keyout "${server_key}" -subj /CN=lm2
openssl x509 -req -in "${server_csr}" -text -days 3650 -CA "${root_cert}" -CAkey "${root_key}" -CAcreateserial -out "${server_cert}"

# create a 10-year grpc client key pair signed by the above ca
openssl req -new -nodes -text -out "${client_csr}" -keyout "${client_key}" -subj /CN=lm2
openssl x509 -req -in "${client_csr}" -text -days 3650 -CA "${root_cert}" -CAkey "${root_key}" -CAcreateserial -out "${client_cert}"
