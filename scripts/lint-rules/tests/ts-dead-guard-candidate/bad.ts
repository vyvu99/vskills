function getName(user: { name?: string } | null) {
  if (!user) return null;
  return user.name;
}
