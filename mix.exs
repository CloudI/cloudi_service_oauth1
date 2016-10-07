defmodule CloudIServiceOauth1 do
  use Mix.Project

  def project do
    [app: :cloudi_service_oauth1,
     version: "1.5.4",
     language: :erlang,
     description: description,
     package: package,
     deps: deps]
  end

  defp deps do
    [# TODO, add cloudi_service_db_pgsql dependencies
     {:cloudi_service_db_pgsql, "~> 1.5.4"},
     {:cowlib, "~> 1.0.0"},
     {:jsx, "~> 2.8.0"},
     {:cloudi_core, "~> 1.5.4"}]
  end

  defp description do
    "Erlang/Elixir Cloud Framework OAuth v1.0 Service"
  end

  defp package do
    [files: ~w(src doc rebar.config README.markdown LICENSE),
     maintainers: ["Michael Truog"],
     licenses: ["BSD"],
     links: %{"Website" => "http://cloudi.org",
              "GitHub" => "https://github.com/CloudI/" <>
                          "cloudi_service_oauth1"}]
   end
end
