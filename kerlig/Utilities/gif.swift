 // Collection of celebration GIFs organized by category
        let successGifs = [
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExazBxeGRkbzM5czV5bXQ4eW81Z2ZhZzZjaWIweHAyOHJ0aHNjZmZ0bCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/cEODGfeOYMRxK/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNzN2OWI2cG9hZDhiZmVkMGp4dHF3ZnI4N2hpYWRpOGJqeWZlZiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/artj92V8o75VPL7AeQ/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTJqMjV0ZWNhcGUzZnNhZGdtazZnMzRkMHN4ZzJlZTVjZGxzeSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYt5jPR6QX5pnqM/giphy.gif",
            "https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExeDg3Mm41NmYwMDgxZDl5aTF2Z2htMDJxcW5kNGo5ZzkzNHMwN3prZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/xHMIDAy1qkzNS/giphy.gif",
            "https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExdmhvZ3kwdDJzbGNrYnNqamsydXFrMWcycXc2MTkwam9venp1Z3lzcCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7abGQa0aRJUurpII/giphy.gif",
            "https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExYTA3eHV6MWpmZ2oxcm9wb2E3N201cmpsMm16ZDNyeXBpZmFpdTQ1ciZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/AL0XsYU0pkFTq/giphy.gif",
            "https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExbjMxZnF3a3AxMjE0bnNydzdlYmxjeXZvem90YzlpdDkxZWtpZ2R4NyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/YPI7uEvEZr7siYRlZD/giphy.gif",
            "https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExNnZpa2NlNDhuZGIzMjY4dnhoYXBhajdpOW9hOWJnMTk1eWQ4Z2ZkZiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYCn3DDRBBqk6nS/giphy.gif",
"https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExcHl0NHkyaXRxaDgwNjkwdWRreG96YmU4M3cxZXRjaGR6dnhpN3dzdyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/d31w24psGYeekCZy/giphy.gif",
"https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExdHVqc2Y1YmFjeG5kajZ0djdmaTR3YnV5MmpybWczc2YwdGNydjR5dSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/LPGLF54a2Wd0Y/giphy.gif",

"https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHkxZXp1aW9jOW93MW1mcHpreXF0a3l5amF0enNzNWF6a3htNW54eCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/K3raI0cXTkzNC/giphy.gif",

"https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExOWE2N3dqY2lvczlzYXR6bGEyOTlqYzh6YmYzNThocHV1endscGhkbSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/8blb81XsdafLy/giphy.gif",

"https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExcHJ0czh5NWU4YWVsYnQzZTc0emlyZGo3dGM0eWdnZGUxZXZ6dTV3dCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/QaXcpBEQRfD9pR3zk5/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMmRiMzJiNGM0ZDJiMzM0ZDM0ZjJkMzY0YzM1ZDM0YzM1ZDM0YyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYJnJA2FYxEV0QM/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNDVkYTRkNmI0YTQ1ZDZiNDVkNmI0NWQ2YjQ1ZDZiNDVkNmI0NWQ2YiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlN5Y28D1wxJI1a/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMzM0ZDM0YzM1ZDM0YzM1ZDM0YzM1ZDM0YzM1ZDM0YzM1ZDM0YyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKDMPKsakcn9NU4/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNWQ2YjQ1ZDZiNDVkNmI0NWQ2YjQ1ZDZiNDVkNmI0NWQ2YjQ1ZDZiNCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/26u4lOMA8JKSnL9Uk/giphy.gif"



        ]
        
        let achievementGifs = [
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHBtdDNwZmZqeGlxYnZicGdkOHd3NnRvbzBuNnpzMWs3YXRqOXhpZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7abIileRivlGr8Nq/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTdvNHFsOHRkZGc2ZHU5cG1zcXV6ZGZ4MjFxcjZtdGNmcGpzNGw2ZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/g9582DNuQppxC/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExYmx6OTEyZXZ3YXNwOGZkYTRnNGdxbWxjMnI0Z2JjOXdtcTdkZiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/LSNqpYqGRqwrS/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMzM0ZDM0YzM1ZDM0YzM1ZDM0YzM1ZDM0YzM1ZDM0YzM1ZDM0YyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKDMPKsakcn9NU4/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMzM0ZDM0YzM1ZDM0YzM1ZDM0YzM1ZDM0YzM1ZDM0YzM1ZDM0YyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKDMPKsakcn9NU4/giphy.gif",
        ]


         let successMessages = [
            "Well done! 💥",
            "Great job! 🎉",
            "Task complete! ✅",
            "Success! 🚀",
            "You did it! 👏",
            "You're on fire! 🔥",
            "You're a machine! 🤖",
            "You're a legend! 💪",
            "You're a boss! 💼",
            "You're a genius! 🧠",
            "You're a wizard! 🧙‍♂️",
            "You're a superhero! 🦸‍♂️",
            "You're a ninja! 🥷",
            "You're a warrior! 💪",
            "You're a legend! 💪",
            "You're a boss! 💼",
            "You're a genius! 🧠",
            "You're a wizard! 🧙‍♂️",
            "You're a superhero! 🦸‍♂️",
        ]
        
        let achievementMessages = [
            "Outstanding! 🏆",
            "Impressive work! 💪",
            "Amazing effort! 🌟",
            "Brilliant! 🔥",
            "Exceptional! 🎯",
            "You're a ninja! 🥷",
            "You're a warrior! 💪",
            "You're a legend! 💪",
            "You're a boss! 💼",
            "You're a genius! 🧠",
            "You're a wizard! 🧙‍♂️",
            "You're a superhero! 🦸‍♂️",
        ]
          let messages = [
                "Task completed successfully!",
                "You finished the task!",
                "One more task down!",
                "Mission accomplished!",
            ]