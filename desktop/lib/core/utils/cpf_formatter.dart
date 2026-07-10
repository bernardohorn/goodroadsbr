/// CPF chega do backend so como 11 digitos (validado por `/^\d{11}$/` no
/// cadastro do mobile) — formata para exibicao (`123.456.789-00`) sem
/// precisar de uma dependencia de mascara.
String? formatCpf(String? cpf) {
  if (cpf == null || cpf.length != 11) return cpf;
  return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
}
