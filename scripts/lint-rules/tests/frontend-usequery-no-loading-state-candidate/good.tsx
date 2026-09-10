export function UserProfile() {
  const { data, isLoading } = useQuery(['user'], fetchUser);
  if (isLoading) return <Spinner />;
  return <div>{data?.name}</div>;
}
