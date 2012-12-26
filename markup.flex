/* Taken from http://www.mediawiki.org/wiki/Markup_spec/flex */
/* Scanner for Wikipedia language.  Built with flex.  */


CARRIAGERETURN                       \r
CARRIAGERETURN_DOUBLE                \r\n\r
VALIDURLCHARS                        [a-z0-9\%\/\?\:\@\=\&\$\_\-\+\!\*\'\(\)\,\.]
NEWPARAGRAPH                         \n\n
MATH                                 <math>
MATH_END                             <\/math>
NOWIKI                               <nowiki>
NOWIKI_END                           <\/nowiki>
GENERICLINK                          [a-z]+:\/\/{VALIDURLCHARS}+
TITLEDLINK                           \133{GENERICLINK}\ [^\133]*\135
WIKILINK                             \133{2}[^\135]+\135{2}
CURRENTDAY                           \{\{CURRENTDAY\}\}
CURRENTMONTH                         \{\{CURRENTMONTH\}\}
CURRENTTIME                          \{\{CURRENTTIME\}\}
CURRENTYEAR                          \{\{CURRENTYEAR\}\}
LIST                                 \n[\:\#\;\*]
PRE                                  ^\040
PRE_END                              \n[^\040]
HR                                   ^----
H1                                   ={1}
H2                                   ={2}
H3                                   ={3}
H4                                   ={4}
H5                                   ={5}
H6                                   ={6}
EMPHASIZE                            '{2}
SEMPHASIZE                           '{3}
VSEMPHASIZE                          '{5}
LESSERTHAN                           <
GREATERTHAN                          >

%option caseless stack
%s list pre
%x math nowiki

%{
#include <time.h>
#include <sys/types.h>

#define MAXLIST 32
%}

%%

%{

/* State variable positions (int state[10]):
0 = pre
1 = h1
2 = h2
3 = h3
4 = h4
5 = h5
6 = h6
7 = emphasis
8 = strong emphasis
9 = very strong emphasis */
int state[10];

/* Temporary variables. */
int i;
char j;

/* A string used for holding the current content of a list (like *#*) */
char listtext[MAXLIST] = "\0";

/* The variables needed for CURRENTTIME-like substitutions. */
time_t time_since_epoch;
struct tm cur_time;

/* Set all state variables to 0. */
for (i=0; i<10; i++) { state[i] = 0; }

/* Get the time once at execution of program, instead of every call. */
time(&time_since_epoch);
gmtime_r(&time_since_epoch, &cur_time);

%}

{CARRIAGERETURN_DOUBLE}              { unput('\n'); }
{CARRIAGERETURN}

{WIKILINK}                           { ECHO; }

{NOWIKI}                             { yy_push_state(nowiki); }
<nowiki>{NOWIKI_END}                 { yy_pop_state(); }
<nowiki>{LESSERTHAN}                 { printf("<"); }
<nowiki>{GREATERTHAN}                { printf(">"); }

{MATH}                               { yy_push_state(math); }
<math>{MATH_END}                     { yy_pop_state(); }

{PRE}                                {
                                     if (state[0] == 0) { printf("\n<pre>"); state[0]++; yy_push_state(pre); }
                                     }
<pre>{PRE_END}                       { printf("</pre>"); state[0]--; yyless(0); yy_pop_state(); }

{HR}                                 { printf("\n<hr>"); }
{NEWPARAGRAPH}                       { printf("\n<p>"); unput('\n'); }

{VSEMPHASIZE}                        {
  if (state[9] == 0) { printf("<strong><em>");   state[9]++; }
  else               { printf("</strong></em>"); state[9]--; }
                                     }
{SEMPHASIZE}                         {
  if (state[8] == 0) { printf("<strong>");  state[8]++; }
  else               { printf("</strong>"); state[8]--; }
                                     }
{EMPHASIZE}                          {
  if (state[7] == 0) { printf("<em>");  state[7]++; }
  else               { printf("</em>"); state[7]--; }
                                     }

{H6}                                 {
  if (state[6] == 0) { printf("<h6>");  state[6]++; }
  else               { printf("</h6>"); state[6]--; }
                                     }
{H5}                                 {
  if (state[5] == 0) { printf("<h5>");  state[5]++; }
  else               { printf("</h5>"); state[5]--; }
                                     }
{H4}                                 {
  if (state[4] == 0) { printf("<h4>");  state[4]++; }
  else               { printf("</h4>"); state[4]--; }
                                     }
{H3}                                 {
  if (state[3] == 0) { printf("<h3>");  state[3]++; }
  else               { printf("</h3>"); state[3]--; }
                                     }
{H2}                                 {
  if (state[2] == 0) { printf("<h2>");  state[2]++; }
  else               { printf("</h2>"); state[2]--; }
                                     }
{H1}                                 {
  if (state[1] == 0) { printf("<h1>");  state[1]++; }
  else               { printf("</h1>"); state[1]--; }
                                     }

{TITLEDLINK}                         {
                                     printf("<a href=\"");
                                     while (*++yytext != ' ') { printf("%c", *yytext); } /* Print everything up to first space */
                                     printf("\">");
                                     while (*++yytext != ']') { printf("%c", *yytext); } /* Print href text */
                                     printf("</a>");
                                     }
{GENERICLINK}                        {
                                     printf("<a href=\"");
                                     j = *(yytext + yyleng - 1);
                                     /* If the last character of a URL is a '.' or a ',', assume it is punctuation. */
                                     if ((j == '.') || (j == ','))
                                       {
                                       *(yytext + yyleng - 1) = '\0';
                                       printf("%s\">%s</a>%c", yytext, yytext, j);
                                       }
                                     else { printf("%s\">%s</a>", yytext, yytext); }
                                     }
{CURRENTTIME}                        { printf("%d:%d", cur_time.tm_hour, cur_time.tm_min); }
{CURRENTDAY}                         { printf("%d", cur_time.tm_mday); }
{CURRENTMONTH}                       { printf("%.2d", (cur_time.tm_mon + 1)); }
{CURRENTYEAR}                        { printf("%d", (cur_time.tm_year + 1900)); }
{LIST}                               {
                                     if (strlen(yytext) < MAXLIST)
                                       {
                                       strcpy(listtext, yytext);
                                       /* 
                                       i = 0;
                                       while(listtext[i] != '\0') {}
                                       */
                                       }
                                     }


%%

int main (int argc, char **argv)
  {
  ++argv, --argc;  /* Don't care about name of program. */
  yyin = fopen(argv[0], "r");
  yylex();
  return 0;
  }