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
static int	g_total;
static int	g_started;

static void	print_banner(void)
{
	if (g_started)
		return ;
	g_started = 1;
	printf("\n========================================\n");
	printf("libft manual eval: %s\n", __FILE__);
	printf("========================================\n");
	printf("Each line shows the case being checked and its result.\n");
}

static void	check(const char *label, int ok)
{
	print_banner();
	g_total++;
	printf("\nTest %02d\n", g_total);
	printf("  check : %s\n", label);
	if (ok)
		printf("  result: OK\n");
	else
	{
		printf("  result: FAIL\n");
		g_fails++;
	}
}

static void	print_result(void)
{
	print_banner();
	printf("\n----------------------------------------\n");
	if (g_fails == 0)
		printf("Summary: PASS (%d/%d checks passed)\n", g_total, g_total);
	else
		printf("Summary: FAIL (%d/%d checks failed)\n", g_fails, g_total);
	printf("----------------------------------------\n");
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
	check("ft_atoi(\"42\") == atoi(\"42\")", ft_atoi("42") == atoi("42"));
	check("ft_atoi(whitespace + -123x) matches atoi", ft_atoi(" \t\n\r\v\f-123x") == atoi(" \t\n\r\v\f-123x"));
	check("ft_atoi(\"+17\") matches atoi", ft_atoi("+17") == atoi("+17"));
	check("ft_atoi(\"--12\") matches atoi", ft_atoi("--12") == atoi("--12"));
	check("ft_atoi(\"0\") == 0", ft_atoi("0") == 0);
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
	check("ft_bzero(a + 2, 3) matches bzero on same buffer", memcmp(a, b, sizeof(a)) == 0);
	ft_bzero(a, 0);
	check("zero-length call leaves buffer unchanged", memcmp(a, b, sizeof(a)) == 0);
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
	check("ft_calloc(8, sizeof(unsigned char)) returns memory", p != NULL);
	zeroed = 1;
	i = 0;
	while (p && i < 8)
		zeroed &= (p[i++] == 0);
	check("ft_calloc returned bytes are all zero", zeroed);
	free(p);
	p = ft_calloc(0, 8);
	check("ft_calloc(0, 8) returns safely", p != NULL || p == NULL);
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
	check("ft_isalpha matches isalpha for -1..128", ok_alpha);
	check("ft_isdigit matches isdigit for -1..128", ok_digit);
	check("ft_isalnum matches isalnum for -1..128", ok_alnum);
	check("ft_isascii is true only for 0..127", ok_ascii);
	check("ft_isprint matches isprint for -1..128", ok_print);
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
	char	label[96];

	got = ft_itoa(n);
	snprintf(label, sizeof(label), "ft_itoa(%d) returns \"%s\"", n, want);
	check(label, got != NULL && strcmp(got, want) == 0);
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
	check("ft_lstnew stores duplicated content pointer", a && strcmp(a->content, "one") == 0);
	ft_lstadd_back(&a, b);
	ft_lstadd_front(&a, c);
	check("ft_lstadd_front/back create a 3-node list", ft_lstsize(a) == 3);
	check("ft_lstlast returns the final node", ft_lstlast(a) == b);
	ft_lstiter(a, upper_content);
	check("ft_lstiter applies callback to list content", strcmp(c->content, "Three") == 0);
	mapped = ft_lstmap(a, dup_content, free);
	check("ft_lstmap duplicates each node into a new list", mapped && ft_lstsize(mapped) == 3);
	ft_lstclear(&mapped, free);
	check("ft_lstclear frees mapped list and sets pointer NULL", mapped == NULL);
	ft_lstclear(&a, free);
	check("ft_lstclear frees original list and sets pointer NULL", a == NULL);
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

	check("ft_memchr finds visible byte 'c'", ft_memchr(buf, 'c', sizeof(buf)) == memchr(buf, 'c', sizeof(buf)));
	check("ft_memchr finds byte after embedded NUL", ft_memchr(buf, 'e', sizeof(buf)) == memchr(buf, 'e', sizeof(buf)));
	check("ft_memchr returns NULL for missing byte", ft_memchr(buf, 'z', sizeof(buf)) == NULL);
	check("ft_memchr with length 0 returns NULL", ft_memchr(buf, 'a', 0) == NULL);
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

	check("comparison equal prefix matches libc", ft_memcmp(a, b, 3) == memcmp(a, b, 3));
	check("ft_memcmp sign matches memcmp for different byte", (ft_memcmp(a, b, 5) < 0) == (memcmp(a, b, 5) < 0));
	check("ft_memcmp with length 0 returns 0", ft_memcmp(a, b, 0) == 0);
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
	check("function returns destination pointer", ft_memcpy(dst, "hello", 6) == dst);
	memcpy(ref, "hello", 6);
	check("ft_memcpy copies bytes like memcpy", memcmp(dst, ref, sizeof(dst)) == 0);
	ft_memcpy(dst, "zz", 0);
	check("zero-length call leaves buffer unchanged", memcmp(dst, ref, sizeof(dst)) == 0);
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

	check("function returns destination pointer", ft_memmove(a + 2, a, 8) == a + 2);
	memmove(b + 2, b, 8);
	check("ft_memmove handles forward overlap like memmove", memcmp(a, b, sizeof(a)) == 0);
	ft_memmove(a, a + 2, 4);
	memmove(b, b + 2, 4);
	check("ft_memmove handles backward overlap like memmove", memcmp(a, b, sizeof(a)) == 0);
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
	check("function returns destination pointer", ft_memset(a, 'A', 5) == a);
	memset(b, 'A', 5);
	check("ft_memset writes bytes like memset", memcmp(a, b, sizeof(a)) == 0);
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
	check("fd output functions printed between BEGIN/END markers", 1);
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
	check("ft_split allocates vector for spaced words", v != NULL);
	check("ft_split word 0 == alpha", v && v[0] && strcmp(v[0], "alpha") == 0);
	check("ft_split word 1 == beta", v && v[1] && strcmp(v[1], "beta") == 0);
	check("ft_split word 2 == gamma", v && v[2] && strcmp(v[2], "gamma") == 0);
	check("ft_split vector ends with NULL terminator", v && v[3] == NULL);
	free_split(v);
	v = ft_split(",,,,", ',');
	check("ft_split on only delimiters gives empty vector", v && v[0] == NULL);
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
	check("ft_strchr finds first 'l' like strchr", ft_strchr(s, 'l') == strchr(s, 'l'));
	check("string search finds terminating NUL like libc", ft_strchr(s, '\0') == strchr(s, '\0'));
	check("ft_strchr returns NULL for missing char", ft_strchr(s, 'z') == NULL);
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
	check("ft_strdup returns allocated duplicate", s != NULL);
	check("ft_strdup content equals source string", s && strcmp(s, "hello") == 0);
	check("ft_strdup result pointer differs from string literal", s && s != (char *)"hello");
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
	check("ft_striteri callback turns abcd into 0123", strcmp(s, "0123") == 0);
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
	check("ft_strjoin allocates joined string", s != NULL);
	check("ft_strjoin result == hello world", s && strcmp(s, "hello world") == 0);
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
	check("ft_strlcat returns full attempted length", ret == 6);
	check("ft_strlcat appends def into abcdef", strcmp(dst, "abcdef") == 0);
	strcpy(dst, "abc");
	ret = ft_strlcat(dst, "def", 4);
	check("ft_strlcat truncated call still returns full length", ret == 6);
	check("ft_strlcat truncates without overflow", strcmp(dst, "abc") == 0);
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
	check("ft_strlcpy returns source length", ret == 5);
	check("ft_strlcpy copies hello into destination", strcmp(dst, "hello") == 0);
	ret = ft_strlcpy(dst, "abcdef", 4);
	check("ft_strlcpy truncated call returns source length", ret == 6);
	check("ft_strlcpy truncates and NUL-terminates", strcmp(dst, "abc") == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strlen)
		cat <<'EOF'
int	main(void)
{
	check("ft_strlen(\"\") matches strlen", ft_strlen("") == strlen(""));
	check("ft_strlen(\"hello\") matches strlen", ft_strlen("hello") == strlen("hello"));
	check("ft_strlen(\"a b c\") matches strlen", ft_strlen("a b c") == strlen("a b c"));
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
	check("ft_strmapi allocates mapped string", s != NULL);
	check("ft_strmapi maps abcd into aceg", s && strcmp(s, "aceg") == 0);
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
	check("comparison equal prefix matches libc", ft_strncmp("abc", "abd", 2) == strncmp("abc", "abd", 2));
	check("ft_strncmp sign matches strncmp", (ft_strncmp("abc", "abd", 3) < 0) == (strncmp("abc", "abd", 3) < 0));
	check("ft_strncmp with n = 0 returns 0", ft_strncmp("abc", "xyz", 0) == 0);
	print_result();
	return (g_fails != 0);
}

EOF
		;;
	ft_strnstr)
		cat <<'EOF'
int	main(void)
{
	check("ft_strnstr finds world inside hello world", ft_strnstr("hello world", "world", 11) != NULL
		&& strcmp(ft_strnstr("hello world", "world", 11), "world") == 0);
	check("ft_strnstr respects max length and misses world", ft_strnstr("hello world", "world", 5) == NULL);
	check("ft_strnstr empty needle returns haystack", ft_strnstr("abc", "", 3) != NULL
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
	check("ft_strrchr finds last 'a' like strrchr", ft_strrchr(s, 'a') == strrchr(s, 'a'));
	check("string search finds terminating NUL like libc", ft_strrchr(s, '\0') == strrchr(s, '\0'));
	check("ft_strrchr returns NULL for missing char", ft_strrchr(s, 'z') == NULL);
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
	check("ft_strtrim allocates trimmed string", s != NULL);
	check("ft_strtrim removes spaces and tabs around hello", s && strcmp(s, "hello") == 0);
	free(s);
	s = ft_strtrim("xxxx", "x");
	check("ft_strtrim trimming all chars returns empty string", s && strcmp(s, "") == 0);
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
	check("ft_substr(hello, 1, 3) == ell", s && strcmp(s, "ell") == 0);
	free(s);
	s = ft_substr("hello", 42, 3);
	check("ft_substr start past end returns empty string", s && strcmp(s, "") == 0);
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
	check("ft_toupper matches toupper for -1..128", ok_upper);
	check("ft_tolower matches tolower for -1..128", ok_lower);
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
