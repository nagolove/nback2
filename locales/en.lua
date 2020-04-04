return {
    language = "English", 
    en = {
        pos = "Position", -- пространство(??)
        position = "Position", 
        sound = "Sound",
        form = "Form",
        color = "Color",

        stat = "Statistic",
        mainMenu = {
            play = "play",
            viewProgress = "view progress",
            help = "help",
            exit = "exit",
        },
        setupMenu = {
            start = "Start",
            expTime = "Expostion time ",
            expTime_sec = " sec.",
            diffLevel = "Difficulty level: ",
            dimLevel = "Dim level: ", -- разница между размерностью и размером поля.
        },
        help = {
            backButton = "Back to main menu",
        },

        waitFor = {
            one = "Wait for %d second",
            few = "Wait for %d seconds",
            many = "Wait for %d seconds",
        },

        settingsBtn = "Settings",
        --backToMainMenu = "Back to menu",
        backToMainMenu = "Main menu",
        --quitBtn = "Back to main", -- лучше назвать - "в главное меню?"
        quitBtn = "Main menu", -- лучше назвать - "в главное меню?"

        today = "today",
        yesterday = "yesterday",
        twoDays  = "two days ago",
        threeDays  = "three days ago",
        fourDays  = "four days ago",
        lastWeek  = "last week",
        lastTwoWeek  = "last two week",
        lastMonth  = "last month",
        lastYear  = "last year",
        moreTime = "more year ago",

        levelInfo1_part1 = {
            one = "Duration %{count} minute", 
            few = "Duration %{count} minutes",
            many = "Duration %{count} minutes",
            other = "Duration %{count} minutes",
        },
        levelInfo1_part2 = {
            one = "%{count} second",
            few = "%{count} seconds",
            many = "%{count} seconds",
            other = "%{count} seconds",
        },

        levelInfo2_part1 = "Level %{count}",
        levelInfo2_part2 = {
            one = "Exposition %{count} second",
            few = "Exposition %{count} seconds",
            many = "Exposition %{count} seconds",
            other = "Exposition %{count} seconds",
        },
    },
}

