# :3

## valid

### libft eval mains

Adds commented manual `main` blocks to every `ft_*.c` file in a 42 libft
project. Run it from the libft root:

```sh
curl -fsSL https://raw.githubusercontent.com/0xveya/goobering/master/scripts/libft_eval_mains.sh | sh
```

Then uncomment exactly one generated block and compile all files together:

```sh
cc -Wall -Wextra -Werror -g ft_*.c -o libft_eval && ./libft_eval
```

Hint for evals: keep the generated blocks commented before submitting. During
evaluation, uncomment one function's block at a time to show what inputs are
tested and the pass/fail result.
