export function useUpdateUser() {
  return useMutation({
    mutationFn: updateUser,
    onSuccess: () => {
      toast.success('Updated');
    },
  });
}
