export function useUpdateUser(form: UseFormReturn) {
  return useMutation({
    mutationFn: updateUser,
    onSuccess: (data) => {
      form.reset(data);
    },
  });
}
