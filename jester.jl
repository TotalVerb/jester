#!/usr/bin/env julia

include("Jokes.jl")

using Iterators
using Mux
using Jokes
using Hiccup
using HttpServer
import HttpServer.FileResponse
import Mux.status, Mux.mimetypes

ormatch(r::RegexMatch, x) = r.match
ormatch(r::Void, x) = x
extension(f) = ormatch(match(r"(?<=\.)[^\.\\/]*$", f), "")
fileheaders(f) = Dict(
  "Content-Type" => get(mimetypes, extension(f), "application/octet-stream"))
redirectheaders(loc) = Dict(
  "Location" => loc)

fileresponse(f) = Dict(
  :file => f,
  :body => open(readbytes, f),
  :headers => fileheaders(f))

function redirect(code::Integer, location::AbstractString)
  req -> Dict(
    :status => code,
    :headers => redirectheaders(location))
end

title(x) = Node(:title, "", x)
p(x) = Node(:p, "", x)
css(href) = Node(:link, "", Dict(:rel=>"stylesheet", :href=>href))
js(src) = Node(:script, "", Dict(:type=>"text/javascript", :src=>src))
@tags a, button, div, header, li, main, nav, span, ul
staticfile(path) = req -> fileresponse(path)

navbar(req) = nav(".navbar.navbar-default",
  div(".container-fluid", [
    div(".navbar-header",
      button(".navbar-toggle.collapsed",
        Dict(
          :type=>"button",
          symbol("data-toggle")=>"collapse",
          symbol("data-target")=>"#navbar",
          symbol("aria-expanded")=>"false",
          symbol("aria-controls")=>"navbar"),
        [
          span(".sr-only", "Toggle navigation"),
          span(".icon-bar", ""),
          span(".icon-bar", ""),
          span(".icon-bar", "")])),
    div("#navbar.navbar-collapse.collapse",
      ul(".nav.navbar-nav", [
        li(a(Dict(:href=>"/"), "Home")),
        li(a(Dict(:href=>"/tag"), "Categories")),
        li(a(Dict(:href=>"/joke"), "All Jokes")),
        li(a(Dict(:href=>"/joke/random"), "Random Joke"))]))]))

pagehead(req, ptitle) = head(
  title("Jester — $ptitle"),
  css("https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"),
  css("/jester.css"),
  js("https://code.jquery.com/jquery-2.1.4.min.js"),
  js("https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"))
pageheader(req, title) = header(".container", [navbar(req), h1(title)])

function joke(req)
  try
    jid = parse(Int, req[:params][:id])
    joke = loadjoke(jid)

    jokebody = map(p, split(joke.data, "\n\n"))
    html(
      pagehead(req, joke.title),
      body(
        pageheader(req, joke.title),
        main(".container", jokebody)))
  catch
    status(404)(staticfile("static/joke-error.html"), req)
  end
end

ljp(title, list, req) = html(
  pagehead(req, title),
  body(
    pageheader(req, title),
    main(".container",
      ul(map(
        e -> li(a(Dict(:href=>"/joke/$(e[1])"), e[2].title)),
        list)))))

listjokes(req) = ljp("List of Jokes", enumerate(jokes()), req)
listtagjokes(req) = ljp(
  "List of Jokes — Tag $(req[:params][:t])",
  filter(j -> symbol(req[:params][:t]) ∈ j[2].category, enumerate(jokes())),
  req)

index(req) = html(
  pagehead(req, "Accountant Jokes and More"),
  body(
    pageheader(req, "Jester"),
    main(".container",
      p("Welcome to Jester! This is your one-stop resource for jokes."))))

randomjoke(req) = redirect(303, "/joke/$(rand(1:thisid()))")(req)

listtags(req) = html(
  pagehead(req, "List of Tags"),
  body(
    pageheader(req, "List of Tags"),
    main(".container",
      ul(map(
        e -> li(a(Dict(:href=>"/tag/$(string(e))"), ucfirst(string(e)))),
        chain(JC_TYPES, JC_TOPICS))))))

@app jester = (
  Mux.defaults,
  page(index),
  page("/jester.css", staticfile("stylesheets/jester.css")),
  page("/joke", listjokes),
  page("/joke/random", randomjoke),
  page("/joke/:id", joke),
  page("/tag", listtags),
  page("/tag/:t", listtagjokes),
  Mux.notfound())

serve(jester)
if !isinteractive()
  wait(Condition())
end
