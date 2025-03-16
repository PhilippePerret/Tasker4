# Pour générer les fichiers locales

# alias TaskerWeb.Gettext.PO
import Gettext #, backend: TaskerWeb.Gettext

langs = ["fr", "en"]
filetypes = ["default", "errors", "ilya", "natures", "tasker"]

langs
|> Enum.each(fn lang ->
  
  code = 
  filetypes
  |> Enum.reduce(%{}, fn filetype, accumulator ->
    path = "priv/gettext/#{lang}/LC_MESSAGES/#{filetype}.po"
    Map.merge(accumulator,
      Expo.PO.parse_file!(path)
        |> Map.get(:messages)
        |> Enum.reduce(%{}, fn imessage, accu ->
          map_msg =
            Map.from_struct(imessage)
            |> Map.take([:msgid, :msgstr, :msg_plural])
          # Note :msgstr est une map quand msg_plural est défini et c'est
          # une liste dans le cas contraire
          msgid   = Enum.at(Map.get(map_msg, :msgid), 0)
          msgplur = Map.get(map_msg, :msg_plural, nil)
          msgstr  = Map.get(map_msg, :msgstr)
          # IO.inspect(msgstr, label: "msgstr initial")
          msgstr  = msgplur && msgstr || Enum.at(msgstr, 0)
          msgstr  = if msgstr == "", do: nil, else: msgstr
          msgstr = 
          case msgstr do
            nil -> nil
            {x, y} -> %{count: x, trans: y} # une autre forme de pluriel
            _ -> msgstr
          end
          # IO.inspect(msgstr, label: "msgstr avant consignation")

          data = if is_nil(msgstr), do: %{}, else: %{trans: msgstr}
          data = if is_nil(msgplur), do: data, else: Map.put(data, :plur, msgplur)
          Map.merge(accu, %{ msgid => data })
        end)
        # |> IO.inspect(label: "Table finale du fichier #{filetype}/#{lang}")
      )
  end)

  # IO.inspect(code, label: "\n\nCODE FINAL")
  dest = "priv/static/assets/js/locales-#{lang}.js"
  code = "window.LOCALES = " <> Jason.encode!(code)
  File.write!(dest, code)

end)
