extends Node
class_name SaveGame

const AUTOSAVE_PATH: String = "user://autosave.cfg"

static func autosave(player_data: PeopleResource, calendar: Node) -> void:
    var cfg := ConfigFile.new()

    if calendar != null:
        if calendar.get("year") != null:
            cfg.set_value("time", "year", int(calendar.get("year")))
        if calendar.get("month_index") != null:
            cfg.set_value("time", "month_index", int(calendar.get("month_index")))
        if calendar.get("week_index") != null:
            cfg.set_value("time", "week_index", int(calendar.get("week_index")))
        if calendar.get("current_energy") != null:
            cfg.set_value("time", "current_energy", int(calendar.get("current_energy")))

    if player_data != null:
        cfg.set_value("player", "person_name", player_data.person_name)
        cfg.set_value("player", "person_age", player_data.person_age)
        cfg.set_value("player", "person_gender", int(player_data.person_gender))
        cfg.set_value("player", "birth_month", player_data.birth_month)
        cfg.set_value("player", "bank_balance", player_data.bank_balance)
        cfg.set_value("player", "highest_education_completed", int(player_data.highest_education_completed))

        cfg.set_value("stats", "Health", player_data.Health)
        cfg.set_value("stats", "Happiness", player_data.Happiness)
        cfg.set_value("stats", "Smarts", player_data.Smarts)
        cfg.set_value("stats", "Looks", player_data.Looks)
        cfg.set_value("stats", "Fitness", player_data.Fitness)
        cfg.set_value("stats", "Stress", player_data.Stress)

        if player_data.current_job != null:
            cfg.set_value("job", "job_name", player_data.current_job.job_name)
            cfg.set_value("job", "company_name", player_data.current_job.company_name)
            cfg.set_value("job", "salary", player_data.current_job.salary)

    cfg.save(AUTOSAVE_PATH)
