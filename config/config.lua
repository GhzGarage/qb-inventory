Config = {
    UseTarget = GetConvar('UseTarget', 'false') == 'true',

    MaxWeight = 120000,
    MaxSlots = 40,

    StashSize = {
        maxweight = 1000000,
        slots = 50
    },

    DropSize = {
        maxweight = 1000000,
        slots = 50
    },

    Keybinds = {
        Open = 'TAB',
        Hotbar = 'Z',
    },

    CleanupDropTime = 15 * 60,
    ItemDropObject = `bkr_prop_duffel_bag_01a`,
    ItemDropObjectBone = 28422,
    ItemDropObjectOffset = {
        vector3(0.260000, 0.040000, 0.000000),
        vector3(90.000000, 0.000000, -78.989998),
    },

    BinObjects = {
        'prop_bin_05a',
    },

    VendingObjects = {
        'prop_vend_soda_01',
        'prop_vend_soda_02',
        'prop_vend_water_01',
        'prop_vend_coffe_01',
    },

    VendingItem = {
        { name = 'kurkakola',    price = 4, amount = 50 },
        { name = 'water_bottle', price = 4, amount = 50 },
    },

    MaximumAmmoValues = {
        ['pistol'] = 250,
        ['smg'] = 250,
        ['shotgun'] = 200,
        ['rifle'] = 250,
    },
}
