# Once Upon a Task

## Run the release

`_build/prod/rel/tasker/bin/tasker start`

## App macos

Après avoir produit la release (et l'avoir vérifiée peut-être), il faut actualiser l'application mac en jouant : 

~~~bash
cd "/Users/philippeperret/Programmes/_Election_wrappers_/Once Upon a Task"
npm run build
mv ./dist/mac-arm64/once-upon-a-task.app "/Applications/Once Upon a Task.app"
~~~

## Server

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
