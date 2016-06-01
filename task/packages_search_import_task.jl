using Genie
using Model
using GitHub
using JSON

type PackagesSearchImportTask
end

function description(_::PackagesSearchImportTask)
  """
  Searches Github for Julia packages and imports them in the DB
  """
end

function run_task!(_::PackagesSearchImportTask, parsed_args = Dict{AbstractString, Any}())
  const github_max_results_limit = 1000
  page_count = 1
  items_count = 0

  while items_count < github_max_results_limit 
    items = search_packages(page_count, items_count)

    for result in items
      items_count += 1
      package = Genie.Package(name = result["name"], url = result["git_url"])
      try 
        Model.create_or_update_by!(package, :url)
      catch ex 
        Genie.log(ex, :debug)
      end
    end
    page_count += 1

    sleep(6) #TODO: fix this to use auth requests 
  end

end

function search_packages(page::Int, items_count::Int)
  const search_url = "https://api.github.com/search/repositories?q=Pkg.+language:julia+in:name,description,readme&sort=stars&order=desc&page=$page"

  response = GitHub.gh_get(search_url)
  results = ( mapreduce(x -> string(Char(x)), *, response.data) |> JSON.parse )
  items = results["items"]
  total_count = results["total_count"]

  return items
end