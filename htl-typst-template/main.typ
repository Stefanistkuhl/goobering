#import "@preview/scaffolder:0.2.1": scaffolding

#set heading(numbering: "1.1.1")
#set text(font: "New Computer Modern")

#let subject = "SUBJECT"
#let class-name = "CLASS"
#let teachers = ("TEACHER 1", "TEACHER 2")
#let students = ("STUDENT NAME 1", "STUDENT NAME 2", "STUDENT NAME 3")
#let group-name = "GROUPNAME"
#let group-number = "GROUP NUMBER"

#let topic = "EXERCISE NAME"
#let exercise-number = "EXERCISE NUMBER"
#let document_title = "template"
#let today = datetime.today()

#set document(title: "Laboratory Protocol")
#set page(
  paper: "a4",
  // background: scaffolding(stroke: blue + 1pt),
  margin: (left: 20mm, right: 20mm, top: 45mm, bottom: 15mm),
  header-ascent: 20pt,
  header: context [
    #stack(dir:ltr, spacing: 1fr,
        [
          htl donaustadt \
          Donaustadtstraße 45 \
          1220 Wien

          Abteilung: Informationstechnologie \
          Schwerpunkt: Netzwerktechnik
        ],
        [
          #image("images/logo.png", width: 35% )
        ],
      )
    #line(length: 100%, stroke: 0.4pt)
  ],
  footer: context [
    #v(12pt)
    #columns(3)[
    #align(left)[#datetime.display(today, "[month repr:long] [day], [year]")]
    #colbreak()
    #align(center)[#document_title]
    #colbreak()
    #align(right)[Page: #counter(page).display("i")]
    ]
  ],
)



#heading(outlined: false,numbering: none)[#topic]
#v(13pt)
#line(length: 100%, stroke: 0.4pt)

Laboratory protocol Excercise #exercise-number: #topic

#image("images/menheraPhoneHello.png", width: 100%)

#v(1fr)
Subject: #subject \
Class: #class-name \
Names: #students.join(", ") \
Groupname/Number: #group-name /#group-number \
Supervisor: #teachers.join(", ") \
Exercise dates: \
Submission date:

#pagebreak()
#outline()

#pagebreak()

#set page(footer: context [
    #v(12pt)
    #columns(3)[
    #align(left)[#datetime.display(today, "[month repr:long] [day], [year]")]
    #colbreak()
    #align(center)[#document_title]
    #colbreak()
    #align(right)[#counter(page).display("1")]
    ]
  ]
)

= Summary <sec:summary> 

#pagebreak()
= Complete network topology of the exercise <sec:network-topology> 

#pagebreak()
= Exercise Execution <sec:exercise-execution> 

== Some Subsection <sec:some-subsection> 

=== Some Subsubsection <sec:some-subsubsection> 

==== Some Paragraph
Some normal text @test \
Some more normal text but here is a citation. @some-source \
*Bold*, _italic_, `mono`, #underline[underlined], #emph[emphasized], #text(size: 8pt)[small] and #text(size: 25pt)[huge] #text(size: 10pt)[text]

#figure(
  block(fill: luma(240), inset: 10pt, radius: 4pt)[
    ```go
//some snippet
fmt.Println("this is a code snippet")
if err != nil {
  fmt.Println("Go is truely a language of all time")
}
    ```
  ],
  caption: [some snippet],
  kind: "snippet",
  supplement: [Listing],
) <snip:snippet-example> 


#figure(
  image("images/menheraPhoneHello.png", width: 20%),
  caption: [Some Figure],
) <fig:figure-example>

Referencing a Figure @fig:figure-example

#pagebreak()
= References <sec:references>
#show bibliography: set heading(outlined: false)
#bibliography("quellen.bib", style: "ieee", title: "References")

#pagebreak()
= List of figures <sec:list-of-figures>
#outline(target: figure.where(kind: image), title: [List of Figures])

#pagebreak()
= List of snippets <sec:list-of-snippets>
#outline(target: figure.where(kind: "snippet"), title: [List of Snippets])
