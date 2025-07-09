pan_contents= {
    ["event"]={
        [1] = {
            chess={{piece=2},{text="chess_tuto_1"}},
            ctrl={
                {text="ctrl_tuto_1_1"}, {stick="leftStick"},
                {text="ctrl_tuto_1_2"},	{but="validate"}
            },
        },
        [2] = {
            ctrl={
                {text="ctrl_tuto_2_1"}, {but="tutoRead"},
            }
        },
        [3] = {
            chess={{piece=3},{text="chess_tuto_3"}},
            ctrl={
                {text="ctrl_tuto_3_1"}, {stick="rightStick"},
                {text="ctrl_tuto_3_2"},	{but="shoot"},
                {line=true},
                {text="ctrl_tuto_3_3"},	{but="reload"}
            }
        },
        [4] = {
            chess={{piece=1},{text="chess_tuto_4"}},
            ctrl={
                {text="ctrl_tuto_4_1"},	{stick="rightStick", stick2="leftStick"},
                {text="ctrl_tuto_4_2"}, {but="pause"}
            }
        },
        [5] = {
            chess={{space=40},{piece=4},{text="chess_tuto_5_1"},{line=true},{piece=0},{text="chess_tuto_5_2"}},
            ctrl={{space=40},
                {text="ctrl_tuto_5_1"},
                {line=true},
                {text="ctrl_tuto_5_2"}, {but="tutoRead"},
                {space=4},
                {text="ctrl_tuto_5_3"}, {but="lstickb"}
            }
        }
    },
    ["breached"]={
        [1]={
            ctrl={
                {text="ctrl_breached_1_1"},
            }
        },
        [2]={
            chess= {{piece=0},{text="chess_breached_1_1"}},
            ctrl = {
                {text="ctrl_breached_1_2"},}
        }
    },
    ["puzzle"]={
        ["2"]={
            chess = {{text="left_puzzle_2_1"}},
            medal={{title="quest"},{text="obj_puzzle_2"},{line= true},{title="threshold"},{medals= true}}
        },
        ["3"]={
            chess = {{text="left_puzzle_3_1"}},
            ctrl = {{text="right_puzzle_3_1"}},
            medal = {{title="quest"},{text="obj_puzzle_3"},{line= true},{title="threshold"},{medals= true}}
        },
        ["4"]={
            ctrl={{text="right_puzzle_4_1"}},
            medal = {{title="quest"},{text="obj_puzzle_4"},{line= true},{title="threshold"},{medals= true}}
        },
        ["5"]={
            chess={{text="left_puzzle_5_1"}, {line=true}, {text="left_puzzle_5_2"}},
            ctrl={{text="right_puzzle_5_1"}},
            medal = {{title="quest"},{text="obj_puzzle_5"},{line= true},{title="threshold"},{medals= true}}
        },

        ["6_1"]={
            chess={{text="left_puzzle_6_1"}},
            medal = {{title="quest"},{text="obj_puzzle_6"},{line= true},{title="threshold"},{medals= true}}
        },
        ["8"]={
            chess={{text="left_puzzle_8"}},
            medal = {{title="quest"},{text="obj_puzzle_8"},{line= true},{title="threshold"},{medals= true}}
        },
		["9"]={
            chess={{text="left_puzzle_9"}},
            medal = {{title="quest"},{text="obj_puzzle_9"},{line= true},{title="threshold"},{medals= true}}
        },
		["10"]={
            chess={{text="left_puzzle_10"}},
            medal = {{title="quest"},{text="obj_puzzle_10"},{line= true},{title="threshold"},{medals= true}}
        },
        ["11"]={
            chess={{text="left_puzzle_11"}},
            medal={{title="quest"},{text="obj_puzzle_11"},{line= true},{title="threshold"},{medals= true}},
        }
    },
    ["card_thief"]={

    }
}