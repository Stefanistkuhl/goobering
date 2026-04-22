#!/usr/bin/env sh
set -eu

MARK_BEGIN='// LIBFT_EVAL_MAIN_BEGIN'
MARK_END='// LIBFT_EVAL_MAIN_END'

usage()
{
	cat <<'USAGE'
Usage:
  sh libft_eval_mains.sh [--uninstall]

Run this from the root of a 42 libft project. It appends managed,
commented-out manual eval mains to every ft_*.c file.

To use one, open a file, uncomment its LIBFT_EVAL_MAIN block, then compile
all ft_*.c files together so libft dependencies are available:

  cc -Wall -Wextra -Werror -g ft_*.c -o libft_eval && ./libft_eval

Examples:
  curl -fsSL https://raw.githubusercontent.com/0xveya/goobering/master/scripts/libft_eval_mains.sh | sh
  sh libft_eval_mains.sh --uninstall
USAGE
}

die()
{
	printf 'libft-eval: %s\n' "$*" >&2
	exit 1
}

need_libft_root()
{
	[ -f ./libft.h ] || die 'run this from a libft root containing libft.h'
	set -- ./ft_*.c
	[ -f "$1" ] || die 'no ft_*.c files found in this directory'
}

remove_managed_block()
{
	file=$1
	tmp=${file}.libft-eval.$$
	awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
		$0 == begin { skip = 1; next }
		$0 == end { skip = 0; next }
		skip != 1 { print }
	' "$file" > "$tmp"
	mv "$tmp" "$file"
}

append_commented_block()
{
	file=$1
	base=${file#./}
	base=${base%.c}

	{
		printf '\n%s\n' "$MARK_BEGIN"
		make_block "$base" | sed 's/^/\/\/ /'
		printf '%s\n' "$MARK_END"
	} >> "$file"
}

common_head()
{
	cat <<'EOF'
/*
Manual libft eval main:
Uncomment exactly one managed block, then run:
cc -Wall -Wextra -Werror -g ft_*.c -o libft_eval && ./libft_eval
*/

# include "libft.h"
# include <ctype.h>
# include <limits.h>
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <unistd.h>

static int	g_fails;

static void	check(const char *label, int ok)
{
	if (ok)
		printf("[OK]   %s\n", label);
	else
	{
		printf("[FAIL] %s\n", label);
		g_fails++;
	}
}

static void	print_result(void)
{
	if (g_fails == 0)
		printf("\nResult: PASS\n");
	else
		printf("\nResult: FAIL (%d)\n", g_fails);
}

EOF
}

common_tail()
{
	:
}

make_block()
{
	name=$1
	common_head
	case "$name" in
	ft_atoi)
		cat <<'EOF'
int	main(void)
{
	check("simple positive", ft_atoi("42") == atoi("42"));
	check("leading whitespace", ft_atoi(" \t\n\r\v\f-123x") == atoi(" \t\n\r\v\f-123x"));
	check("plus sign", ft_atoi("+17") == atoi("+17"));
	check("double sign", ft_atoi("--12") == atoi("--12"));
	check("zero", ft_atoi("0") == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_bzero)
		cat <<'EOF'
int	main(void)
{
	char	a[8] = "abcdefg";
	char	b[8] = "abcdefg";

	ft_bzero(a + 2, 3);
	bzero(b + 2, 3);
	check("partial clear matches bzero", memcmp(a, b, sizeof(a)) == 0);
	ft_bzero(a, 0);
	check("zero length keeps buffer", memcmp(a, b, sizeof(a)) == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_calloc)
		cat <<'EOF'
int	main(void)
{
	unsigned char	*p;
	size_t			i;
	int				zeroed;

	p = ft_calloc(8, sizeof(unsigned char));
	check("allocation returns memory", p != NULL);
	zeroed = 1;
	i = 0;
	while (p && i < 8)
		zeroed &= (p[i++] == 0);
	check("memory is zeroed", zeroed);
	free(p);
	p = ft_calloc(0, 8);
	check("zero count does not crash", p != NULL || p == NULL);
	free(p);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_is_things)
		cat <<'EOF'
int	main(void)
{
	int	c;
	int	ok_alpha;
	int	ok_digit;
	int	ok_alnum;
	int	ok_ascii;
	int	ok_print;

	ok_alpha = 1;
	ok_digit = 1;
	ok_alnum = 1;
	ok_ascii = 1;
	ok_print = 1;
	c = -1;
	while (c <= 128)
	{
		ok_alpha &= (!!ft_isalpha(c) == !!isalpha(c));
		ok_digit &= (!!ft_isdigit(c) == !!isdigit(c));
		ok_alnum &= (!!ft_isalnum(c) == !!isalnum(c));
		ok_ascii &= (!!ft_isascii(c) == (c >= 0 && c <= 127));
		ok_print &= (!!ft_isprint(c) == !!isprint(c));
		c++;
	}
	check("ft_isalpha range", ok_alpha);
	check("ft_isdigit range", ok_digit);
	check("ft_isalnum range", ok_alnum);
	check("ft_isascii range", ok_ascii);
	check("ft_isprint range", ok_print);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_itoa)
		cat <<'EOF'
static void	check_itoa(int n, const char *want)
{
	char	*got;

	got = ft_itoa(n);
	check(want, got != NULL && strcmp(got, want) == 0);
	free(got);
}

int	main(void)
{
	check_itoa(0, "0");
	check_itoa(42, "42");
	check_itoa(-42, "-42");
	check_itoa(INT_MAX, "2147483647");
	check_itoa(INT_MIN, "-2147483648");
	print_result();
	return (g_fails != 0);
}

EOF
		;;
ft_lst*)
		cat <<'EOF'
static void	upper_content(void *p)
{
	char	*s;

	s = p;
	if (s && s[0] >= 'a' && s[0] <= 'z')
		s[0] -= 32;
}

static void	*dup_content(void *p)
{
	return (ft_strdup((char *)p));
}

int	main(void)
{
	t_list	*a;
	t_list	*b;
	t_list	*c;
	t_list	*mapped;

	a = ft_lstnew(ft_strdup("one"));
	b = ft_lstnew(ft_strdup("two"));
	c = ft_lstnew(ft_strdup("three"));
	check("ft_lstnew content", a && strcmp(a->content, "one") == 0);
	ft_lstadd_back(&a, b);
	ft_lstadd_front(&a, c);
	check("ft_lstsize after add", ft_lstsize(a) == 3);
	check("ft_lstlast", ft_lstlast(a) == b);
	ft_lstiter(a, upper_content);
	check("ft_lstiter touched first", strcmp(c->content, "Three") == 0);
	mapped = ft_lstmap(a, dup_content, free);
	check("ft_lstmap produced list", mapped && ft_lstsize(mapped) == 3);
	ft_lstclear(&mapped, free);
	check("ft_lstclear nulls mapped", mapped == NULL);
	ft_lstclear(&a, free);
	check("ft_lstclear nulls original", a == NULL);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_memchr)
		cat <<'EOF'
int	main(void)
{
	const char	buf[] = "abc\0def";

	check("find visible byte", ft_memchr(buf, 'c', sizeof(buf)) == memchr(buf, 'c', sizeof(buf)));
	check("find byte after nul", ft_memchr(buf, 'e', sizeof(buf)) == memchr(buf, 'e', sizeof(buf)));
	check("missing byte", ft_memchr(buf, 'z', sizeof(buf)) == NULL);
	check("zero length", ft_memchr(buf, 'a', 0) == NULL);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_memcmp)
		cat <<'EOF'
int	main(void)
{
	unsigned char	a[] = {0, 1, 2, 200, 0};
	unsigned char	b[] = {0, 1, 2, 201, 0};

	check("equal prefix", ft_memcmp(a, b, 3) == memcmp(a, b, 3));
	check("different byte sign", (ft_memcmp(a, b, 5) < 0) == (memcmp(a, b, 5) < 0));
	check("zero length", ft_memcmp(a, b, 0) == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_memcpy)
		cat <<'EOF'
int	main(void)
{
	char	dst[16];
	char	ref[16];

	memset(dst, 'x', sizeof(dst));
	memset(ref, 'x', sizeof(ref));
	check("return value", ft_memcpy(dst, "hello", 6) == dst);
	memcpy(ref, "hello", 6);
	check("copy matches memcpy", memcmp(dst, ref, sizeof(dst)) == 0);
	ft_memcpy(dst, "zz", 0);
	check("zero length keeps buffer", memcmp(dst, ref, sizeof(dst)) == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_memmove)
		cat <<'EOF'
int	main(void)
{
	char	a[16] = "0123456789";
	char	b[16] = "0123456789";

	check("return value", ft_memmove(a + 2, a, 8) == a + 2);
	memmove(b + 2, b, 8);
	check("overlap forward", memcmp(a, b, sizeof(a)) == 0);
	ft_memmove(a, a + 2, 4);
	memmove(b, b + 2, 4);
	check("overlap backward", memcmp(a, b, sizeof(a)) == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_memset)
		cat <<'EOF'
int	main(void)
{
	char	a[8];
	char	b[8];

	memset(a, 0, sizeof(a));
	memset(b, 0, sizeof(b));
	check("return value", ft_memset(a, 'A', 5) == a);
	memset(b, 'A', 5);
	check("matches memset", memcmp(a, b, sizeof(a)) == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_putchar_fd|ft_putendl_fd|ft_putnbr_fd|ft_putstr_fd)
		cat <<'EOF'
int	main(void)
{
	printf("Expected visible output between markers:\n<BEGIN>\n");
	ft_putchar_fd('A', 1);
	ft_putchar_fd('\n', 1);
	ft_putstr_fd("hello", 1);
	ft_putchar_fd('\n', 1);
	ft_putendl_fd("world", 1);
	ft_putnbr_fd(0, 1);
	ft_putchar_fd('\n', 1);
	ft_putnbr_fd(-2147483648, 1);
	ft_putchar_fd('\n', 1);
	printf("<END>\n");
	check("fd functions ran", 1);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_split)
		cat <<'EOF'
static void	free_split(char **v)
{
	size_t	i;

	if (!v)
		return ;
	i = 0;
	while (v[i])
		free(v[i++]);
	free(v);
}

int	main(void)
{
	char	**v;

	v = ft_split("  alpha beta  gamma ", ' ');
	check("split allocation", v != NULL);
	check("word 0", v && v[0] && strcmp(v[0], "alpha") == 0);
	check("word 1", v && v[1] && strcmp(v[1], "beta") == 0);
	check("word 2", v && v[2] && strcmp(v[2], "gamma") == 0);
	check("terminator", v && v[3] == NULL);
	free_split(v);
	v = ft_split(",,,,", ',');
	check("only delimiters gives empty vector", v && v[0] == NULL);
	free_split(v);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strchr)
		cat <<'EOF'
int	main(void)
{
	const char	*s;

	s = "hello";
	check("find first l", ft_strchr(s, 'l') == strchr(s, 'l'));
	check("find nul", ft_strchr(s, '\0') == strchr(s, '\0'));
	check("missing char", ft_strchr(s, 'z') == NULL);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strdup)
		cat <<'EOF'
int	main(void)
{
	char	*s;

	s = ft_strdup("hello");
	check("duplicate allocation", s != NULL);
	check("duplicate content", s && strcmp(s, "hello") == 0);
	check("different pointer", s && s != (char *)"hello");
	free(s);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_striteri)
		cat <<'EOF'
static void	iter_cb(unsigned int i, char *c)
{
	*c = (char)('0' + i);
}

int	main(void)
{
	char	s[] = "abcd";

	ft_striteri(s, iter_cb);
	check("callback changed chars", strcmp(s, "0123") == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strjoin)
		cat <<'EOF'
int	main(void)
{
	char	*s;

	s = ft_strjoin("hello", " world");
	check("join allocation", s != NULL);
	check("join content", s && strcmp(s, "hello world") == 0);
	free(s);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strlcat)
		cat <<'EOF'
int	main(void)
{
	char	dst[16] = "abc";
	size_t	ret;

	ret = ft_strlcat(dst, "def", sizeof(dst));
	check("return length", ret == 6);
	check("concat content", strcmp(dst, "abcdef") == 0);
	strcpy(dst, "abc");
	ret = ft_strlcat(dst, "def", 4);
	check("truncated return length", ret == 6);
	check("truncated content", strcmp(dst, "abc") == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strlcpy)
		cat <<'EOF'
int	main(void)
{
	char	dst[8];
	size_t	ret;

	memset(dst, 'x', sizeof(dst));
	ret = ft_strlcpy(dst, "hello", sizeof(dst));
	check("return source length", ret == 5);
	check("copy content", strcmp(dst, "hello") == 0);
	ret = ft_strlcpy(dst, "abcdef", 4);
	check("truncate return source length", ret == 6);
	check("truncate content", strcmp(dst, "abc") == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strlen)
		cat <<'EOF'
int	main(void)
{
	check("empty", ft_strlen("") == strlen(""));
	check("normal", ft_strlen("hello") == strlen("hello"));
	check("with spaces", ft_strlen("a b c") == strlen("a b c"));
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strmapi)
		cat <<'EOF'
static char	map_cb(unsigned int i, char c)
{
	return ((char)(c + i));
}

int	main(void)
{
	char	*s;

	s = ft_strmapi("abcd", map_cb);
	check("mapped allocation", s != NULL);
	check("mapped content", s && strcmp(s, "aceg") == 0);
	free(s);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strncmp)
		cat <<'EOF'
int	main(void)
{
	check("equal prefix", ft_strncmp("abc", "abd", 2) == strncmp("abc", "abd", 2));
	check("different sign", (ft_strncmp("abc", "abd", 3) < 0) == (strncmp("abc", "abd", 3) < 0));
	check("zero length", ft_strncmp("abc", "xyz", 0) == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strnstr)
		cat <<'EOF'
int	main(void)
{
	check("find needle", ft_strnstr("hello world", "world", 11) != NULL
		&& strcmp(ft_strnstr("hello world", "world", 11), "world") == 0);
	check("limited miss", ft_strnstr("hello world", "world", 5) == NULL);
	check("empty needle", ft_strnstr("abc", "", 3) != NULL
		&& strcmp(ft_strnstr("abc", "", 3), "abc") == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strrchr)
		cat <<'EOF'
int	main(void)
{
	const char	*s;

	s = "banana";
	check("last a", ft_strrchr(s, 'a') == strrchr(s, 'a'));
	check("find nul", ft_strrchr(s, '\0') == strrchr(s, '\0'));
	check("missing", ft_strrchr(s, 'z') == NULL);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strtrim)
		cat <<'EOF'
int	main(void)
{
	char	*s;

	s = ft_strtrim(" \t hello \t ", " \t");
	check("trim allocation", s != NULL);
	check("trim content", s && strcmp(s, "hello") == 0);
	free(s);
	s = ft_strtrim("xxxx", "x");
	check("trim all", s && strcmp(s, "") == 0);
	free(s);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_substr)
		cat <<'EOF'
int	main(void)
{
	char	*s;

	s = ft_substr("hello", 1, 3);
	check("middle substring", s && strcmp(s, "ell") == 0);
	free(s);
	s = ft_substr("hello", 42, 3);
	check("start past end", s && strcmp(s, "") == 0);
	free(s);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_to_upper_to_lower)
		cat <<'EOF'
int	main(void)
{
	int	c;
	int	ok_upper;
	int	ok_lower;

	ok_upper = 1;
	ok_lower = 1;
	c = -1;
	while (c <= 128)
	{
		ok_upper &= (ft_toupper(c) == toupper(c));
		ok_lower &= (ft_tolower(c) == tolower(c));
		c++;
	}
	check("toupper range", ok_upper);
	check("tolower range", ok_lower);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	*)
		cat <<EOF
int	main(void)
{
	printf("No custom eval main is defined for this file yet.\\n");
	check("compiled with all ft_*.c dependencies", 1);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	esac
	common_tail
}

uninstall()
{
	need_libft_root
	for file in ./ft_*.c; do
		remove_managed_block "$file"
	done
	rm -f ./libft-eval-ui.sh ./libft_eval
	rm -rf ./.libft-eval
	printf 'libft-eval: removed managed eval mains\n'
}

install()
{
	need_libft_root
	for file in ./ft_*.c; do
		remove_managed_block "$file"
		append_commented_block "$file"
	done
	printf 'libft-eval: installed commented eval mains in ft_*.c files\n'
	printf 'libft-eval: uncomment one block manually, then run:\n'
	printf '  cc -Wall -Wextra -Werror -g ft_*.c -o libft_eval && ./libft_eval\n'
}

case "${1-}" in
--help|-h)
	usage
	;;
--uninstall)
	uninstall
	;;
'')
	install
	;;
*)
	usage >&2
	exit 2
	;;
esac
