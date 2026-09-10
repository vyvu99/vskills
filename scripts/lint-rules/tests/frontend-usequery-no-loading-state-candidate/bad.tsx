export function UserProfile() {
  const { data } = useQuery(['user'], fetchUser);
  return <div>{data?.name}</div>;
}
