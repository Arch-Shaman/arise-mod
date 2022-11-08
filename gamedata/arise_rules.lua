-- Arise ruleset --

local rules = {
	costFactor         = 2,       -- how much more expensive factories are per level, in terms of initial cost.
	maxLevel           = 10,      -- maximum level that can be obtained.
	upgradeTimeMax     = 60,      -- in seconds
	upgradeFactor      = 0.1,     -- percentage boost.
	payForNewFactories = false,   -- set to true to make cons pay for new factory.
}

return rules
