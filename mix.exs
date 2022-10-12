#-*-Mode:elixir;coding:utf-8;tab-width:2;c-basic-offset:2;indent-tabs-mode:()-*-
# ex: set ft=elixir fenc=utf-8 sts=2 ts=2 sw=2 et nomod:

defmodule CloudIServiceOauth1 do
  use Mix.Project

  def project do
    [app: :cloudi_service_oauth1,
     version: "2.0.5",
     language: :erlang,
     erlc_options: [
       {:d, :erlang.list_to_atom('ERLANG_OTP_VERSION_' ++ :erlang.system_info(:otp_release))},
       :deterministic,
       :debug_info,
       :warn_export_vars,
       :warn_unused_import,
       #:warn_missing_spec,
       :warnings_as_errors],
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [
       :cloudi_core,
       :cowlib,
       :jsx,
       :crypto,
       :public_key,
       :inets]]
  end

  defp deps do
    [{:cloudi_service_db_pgsql, ">= 2.0.5"},
     {:cowlib, ">= 2.11.0"},
     {:jsx, ">= 3.1.0"},
     {:cloudi_core, ">= 2.0.5"}]
  end

  defp description do
    "Erlang/Elixir Cloud Framework OAuth v1.0 Service"
  end

  defp package do
    [files: ~w(src doc test rebar.config README.markdown LICENSE),
     maintainers: ["Michael Truog"],
     licenses: ["MIT"],
     links: %{"Website" => "https://cloudi.org",
              "GitHub" => "https://github.com/CloudI/" <>
                          "cloudi_service_oauth1"}]
   end
end
