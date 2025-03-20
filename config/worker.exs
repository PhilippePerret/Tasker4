# Préférences du travailleur
#
#



# :work_start_time {H:MM}
# Heure de début de travail

# :morning_end_time  {H:MM}
# Heure de fin de première tranche de travail

# :midday_start_time  {H:MM}
# Heure de reprise du travail après le lunch

# :work_end_time  {H:MM}
# Heure de fin de travail de la journée

# :sort_by_task_duration {nil|:long|:short}
# Si :long, on privilégie les tâches longues, si :short, les tâches
# courtes et si nil, on ne fait rien.

# :sort_by_task_difficulty {nil|:hard|:easy}
# Si :hard, on privilégie les tâches difficiles, si :easy, on privi-
# légie les tâches facile et si nil, on ne fait rien

# :default_task_duration {nil|<nombre de minutes>}
# Durée par défaut d'une tâche

# :prioritize_same_nature {true|false|nil}
# Si true, on privilégie les tâches de même nature, si false, on les
# disqualifie. Nil permet de ne rien faire.

# :alert_for_exclusive
# Si true, une alerte sera générée pour toutes les tâches exclusives
# Le temps est défini ci-dessus

# :time_before_alert
# Le temps avant la tâche pour l'alerte. Par défaut, c'est un jour
# avant, à la même heure que la tâche ou à l'heure spécifiée 
# ci-desouss

# :alert_hour
# Heure à laquelle l'alerte doit être donnée. Par défaut, c'est la 
# même que l'heure de la tâche.