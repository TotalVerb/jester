#!/usr/bin/env julia
include("Jokes.jl")

using ArgParse
using Jokes

function askcategory!(set, metacat, options)
  println("Please pick a suitable $metacat for this joke:")
  for (i, category) in enumerate(options)
    println(" $i) $(string(category))")
  end
  print("Please select the $metacat above, or 0 for none: ")
  uinput = parse(Int, strip(readline()))
  if uinput > 0
    push!(set, options[uinput])
  end
end

function main(args)
  s = ArgParseSettings(
    description = "Read and write jokes into Jester.")

  @add_arg_table s begin
    "read"
      action = :command
      help = "read a joke"
    "create"
      action = :command
      help = "create a new joke"
    "list"
      action = :command
      help = "list all jokes"
  end

  @add_arg_table s["read"] begin
    "arg1"
      arg_type = Int
      help = "id of the joke to read"
  end

  parsed_args = parse_args(s)

  if parsed_args["%COMMAND%"] == "read"
    joke = loadjoke(parsed_args["read"]["arg1"])
    println("Title: $(joke.title)")
    println(joke.data)
  elseif parsed_args["%COMMAND%"] == "create"
    print("Title of new joke: ")
    title = strip(readline())
    println("Content of new joke (type [END] to end): ")
    lines = UTF8String[]
    while true
      line = readline()
      if strip(line) == "[END]"
        break
      end
      push!(lines, strip(line))
    end
    data = join(lines, "\n")

    cats = Set{Symbol}()
    askcategory!(cats, "subject", JC_TOPICS)
    askcategory!(cats, "type", JC_TYPES)

    id = nextid()
    joke = Joke(title, data, cats)
    savejoke(id, joke)

    println("Joke #$id, \"$title\" saved!")
  elseif parsed_args["%COMMAND%"] == "list"
    println("List of Jokes")
    for (i, joke) in enumerate(jokes())
      println(" $i) $(joke.title)")
    end
  end
end

main(ARGS)
