defmodule PhilTextFormater do
  @moduledoc """

  TODO
  ====
    - formater les liens [title](path|route)
    - traiter le sélecteur d'amorce particulier .inline, pour mettre
      tous les éléments qu'il contient sur la même ligne. Par ex. :
      .inline:
        [lien 1](path/to/lien1)
        [lien 2](path/to/lien2)
        [lien 3](path/to/lien3)
      Ces trois liens seront sur la même ligne (<p> par défaut)
    - traiter les codes à évaluer: <%= un_code %>


  Module de formattage de mon format de fichier conçu spécialement
  pour le web. Car le grand problème de markdown, c'est de ne pas
  fournir nativement la possibilité de définir des classes et des
  identifiant.

  Un fichier PhilText soit posséder l'extension .phil. Par exemple :

      monfichier.phil

  Une ligne de PhilText, si elle doit être formatée ressemble à : 

      <tag>.<class>#<identifiant>: <contenu textuel>
  
  La partie « <tag>.<class>#<identifiant>: » s'appelle l'AMORCE.
  Elle ne doit contenir que les caractères autorisés pour les sélec-
  teurs et surtout aucune espace.

  Si une ligne ne contient pas d'amorce, par exemple : 

      <contenu textuel>

  … elle sera formatée dans un <p> sauf si les métadonnées définis-
  sent une 'default_tag' différente (cf. ci-dessous).

  On peut aussi séparer sur deux lignes l'amorce et le contenu 
  textuel :

      <tag>.<class>#<di>:
        <contenu textuel>
  
  Dans ce cas, il est impératif d'indenter d'une tabulation ou de
  deux espaces le contenu textuel.

  Cette syntaxe est pratique si plusieurs contenus textuels succes-
  sifs doivent partager la même amorce :

      <tag>.<class>#<di>:
        <contenu textuel>
        <autre contenu textuel avec même amorce>
        <autre contenu textuel avec même amorce aussi>
        etc.
  
  Mais on peut en faire une autre utilisation si l'amorce contient le
  sélecteur ”.inline“. dans ce cas, les éléments seront tous mis en
  ligne. Par exemple pour des liens centrés sur la page :

        .center.inline:
          [Premier lien](https: //path/to/lien1)
          [Deuxième lien](route/to/lien2)
          [Troisième lien](route/to/lien3)


  FRONT-MATTER/METADATA
  ------------
    La page complète peut contenir un front-matter qui définit les
    métadonnées à prendre en considération.

        ----- Début du document -----
        ---
        <définition des métadonnées>
        ---
        <contenu textuel>
        ----- Fin du document -----

    Chaque ligne du front-matter doit obligatoirement être définie
    sous la forme : 
        variable = valeur

    Ces métadonnées peuvent définir :

      default_tag     Balise par défaut (par défaut, c'est <p>)
      image_folder    Chemin d'accès aux dossier des images.

  """

  @doc """
  Retourne le fichier de chemin d'accès +path+. Dans l'usage courant,
  c'est le chemin d'accès au fichier HTML qui est fourni. Mais on 
  peut transmettre aussi le fichier .phil

  Si le fichier .phil a été actualisé depuis la dernière utilisation,
  le fichier HTML sera actualisé. Sinon le fichier HTML sera directe-
  ment renvoyé.

  """
  def get_phil_text(path) do
    dst_path = path
    fname   = Path.basename(path)
    fext    = Path.extname(path) # .phil ou .html
    faffix  = Path.basename(path, fext)
    folder  = Path.dirname(path)

    src_path  = Path.join([folder, "#{faffix}.phil"])
    dst_path  = Path.join([folder, "#{faffix}.html"])

    src_exists = File.exists?(src_path)
    dst_exists = File.exists?(dst_path)

    if not(src_exists) and not(dst_exists) do
      ~s(<span style="color:red;"> Contenu introuvable</span>)
    else
      dst_date = dst_exists && mtime(dst_path) || nil
      src_date = src_exists && mtime(src_path) || nil

      if not(dst_exists) or DateTime.after?(src_date, dst_date) do
        # <= Fichier HTML inexistant ou pas à jour
        # => On le reconstruit et on le retourne
        code = rebuild_phil_text(src_path)
        File.write!(dst_path, code)
      end
      File.read!(dst_path)
    end
  end

  defp mtime(path) do
    File.lstat!(path).mtime
    |> NaiveDateTime.from_erl!()
    |> DateTime.from_naive!("Etc/UTC")
  end

  @smalltag_to_realtag %{
    ""  => "p", # par défaut
    "p" => "p",
    "d" => "div",
    "q" => "quote"
  }

  @reg_amorce_attributes ~r/^([pdq]?)((?:[\.\#][a-zA-Z0-9_\-]+)+)?\:/
  @reg_amorce_et_texte   ~r/#{Regex.source(@reg_amorce_attributes)}(.+)$/
  # @reg_amorce_et_texte   ~r/^([pdq]?)((?:[\.\#][a-zA-Z0-9_\-]+)+)?\:(.+)$/
  def rebuild_phil_text(src) do
    [metadata, content] =
    File.read!(src)
    |> split_front_matter()
    |> front_matter_to_metadata()

    default_tag = Keyword.get(metadata, :default_tag, "p")

    content = content
    |> treate_returns()
    |> String.split("\n")
    |> Enum.map(fn line ->
      line = String.trim(line)
      scanner = Regex.scan(@reg_amorce_et_texte, line)
      # |> IO.inspect(label: "Scan de ligne '#{line}'")
      cond do
        line == "" -> nil
        Enum.empty?(scanner) ->
          ~s(<#{default_tag}>#{treate_content(line, metadata)}</#{default_tag}>)
        true ->
          scanner = Enum.at(scanner, 0)
          [_tout, tag, selectors, content] = scanner
          tag = @smalltag_to_realtag[tag]
          selectors = extract_attributes_from(selectors)
          |> IO.inspect(label: "sélectors finaux")
          tag = tag == "" && "p" || tag
          ~s(<#{tag}#{selectors}>#{treate_content(content, metadata)}</#{tag}>)
      end
    end)
    |> Enum.filter(fn fline -> not is_nil(fline) end)
    |> Enum.join("\n")
  end


  def treate_content(content, metadata) do
    content
    |> treate_alinks_in(metadata)
    |> treate_simple_formatages(metadata)
  end

  @doc """
  Traitement des liens comme dans markdown

  ## Examples

    iex> treate_alinks_in("[Titre](/to/route)", [])
    ~s(<a href="/to/route">Titre</a>)
    
  """
  @reg_alinks ~r/\[(.+)\]\((.+)\)/U
  def treate_alinks_in(content, metadata) do
    Regex.replace(@reg_alinks, content, fn _, title, route ->
      ~s(<a href="#{route}">#{title}</a>)
    end)
  end

  @doc """
  Traitement des formatages simples hérités de markdown

  ## Examples

    iex> treate_simple_formatages("*italic*", [])
    "<em>italic</em>"

  """
  def treate_simple_formatages(content, metadata) do
    content
  end


  def split_front_matter(str) do
    parts = String.split(str, "---")
    if Enum.count(parts) == 3 do
      [_rien | usefull_parts] = parts
      usefull_parts
    else
      [nil, str]
    end
  end

  def front_matter_to_metadata([frontmatter, content]) do
    metadata =
    if is_nil(frontmatter) do
      []
    else
      String.trim(frontmatter)
      |> String.split("\n")
      |> Enum.map(fn line -> 
        [var, value] = String.split(line, "=") |> Enum.map(fn s -> String.trim(s) end)
        {String.to_atom(var), value}
      end)
    end
    [metadata, String.trim(content)]
    # |> IO.inspect(label: "Fin de découpe")
  end

  # Le texte du fichier peut contenir des formatages tels que :
  # 
  #     p.class:
  #       Ma ligne de texte
  #       Mon autre ligne de texte
  # 
  # Il faut les reconstituer en :
  # 
  #     p.class: Ma ligne de texte
  #     p.class: Mon autre ligne de texte
  # 
  @reg_indented_format ~r/#{Regex.source(@reg_amorce_attributes)}(?:\n(?:\t|  )(?:.+))+/m
  defp treate_returns(str) do
    Regex.replace(@reg_indented_format, str, fn tout, _ -> 
      [amorce | phrases] = 
      tout
      |> String.replace("\n  ", "\n\t")
      |> String.split("\n\t")
      # IO.inspect(amorce, label: "Amorce")
      # IO.inspect(phrases, label: "Tail")

      if String.match?(amorce, ~r/\.inline/) do
        amorce = String.replace(amorce, ".inline", "")
        # Traitement spécial de texte en ligne
        phrases = phrases
        |> Enum.map(fn p -> String.trim(p) end)
        |> Enum.join(" ")
        amorce <> phrases
      else
        # On ajoute l'amorce à tous les segments
        phrases
        |> Enum.map(fn seg -> amorce <> seg end)
        |> Enum.join("\n")
      end
    end)
    # |> IO.inspect(label: "Texte reformaté")
  end

  defp extract_attributes_from(str) do
    attributes = 
    Regex.scan(~r/(?:([.#])([a-zA-Z0-9_\-]+))/, str) 
    |> Enum.reduce(%{id: nil, class: ""}, fn [_tout, type, selector], collector -> 
      [type, selector] 
      if type == "." do
        %{collector | class: collector.class <> selector <> " " }
      else
        %{collector | id: selector}
      end
    end)
    # |> IO.inspect(label: "Comme table")
    |> Enum.reduce("", fn {attr, value}, accu -> 
      if is_nil(value) or String.trim(value) == "" do
        accu
      else
        accu <> ~s( #{attr}="#{String.trim(value)}")
      end
    end)
    |> String.trim()
    if attributes == "" do
      ""
    else
      " #{attributes}"
    end
  end

end