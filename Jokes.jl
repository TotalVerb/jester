module Jokes

using Compat
using JLD

# Management of the index file.
function loadindex()
  try
    ind = load("./jokes/index.jld")
  catch
    Dict{UTF8String, Any}(
      "id" => 0)
  end
end

saveindex(ind) = save("./jokes/index.jld", ind)
function nextid()
  ind = loadindex()
  ind["id"] += 1
  saveindex(ind)
  ind["id"]
end
thisid() = loadindex()["id"]

# Joke categories.
JC_TOPICS = [:accountant, :chicken, :food, :tennis]
JC_TYPES = [:pun]

type Joke
  title::UTF8String
  data::UTF8String
  category::Set{Symbol}
end

# Individual joke functions
loadjoke(id::Integer) = load("./jokes/$id.jld", "joke")
function savejoke(id::Integer, joke::Joke)
  save("./jokes/$id.jld", "id", id, "joke", joke)
end

# Collective joke functions
jokes() = map(loadjoke, 1:thisid())

export JC_TOPICS, JC_TYPES
export Joke, loadjoke, savejoke
export nextid, thisid, jokes

end
