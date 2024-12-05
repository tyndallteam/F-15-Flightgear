Zaretto FlightGear Aircraft Models
-----------------------------------------------

Aircraft directory contains the FlightGear aircraft models by Richard Harrison

F-15 - C and D variants. http://zaretto.com/f-15. JSBSim aero model, external model by flying_toaster; cockpit photo textures by geneb.

-----------------------------------------------------------------
Contributions are welcomed. If there's something you want to improve or fix raise an issue here. If you know what you want to do then spell it out in the issue. https://github.com/Zaretto/fg-aircraft/issues

Branches are as follows:
* master is generally where I do most of the development. the 
* develop I use only for large changes (to keep master free from in development breaking changes). 
* flightgear-release branch is generally what I use to make the archives that are distributed on my page.

It is best if you reference the issue in the commit or pull message.

So to summarise;

- communicate by raising an issue
- contribute by making the changes to the master branch, test and then when you're happy generate a pull request
- wait for the pull request to be reviewed and accepted. 

------

V1.12 Changes

## RELEASE NOTES -  .

F-15:
* TEWS improvements
* VSD improvements
* MPCD SIT map rewrite
* Emesary damage
* Hyds, JFS simulation model improved
* aero model improved for flaps.
* nasal performance improvements
* weapons, radar updates.

#### Change summary for 1.12:
+ 2022-10-19  F-15: Move revised autopilot dialog
+ 2022-10-19  F-15: Finish emexec changes
+ 2022-10-16  F-15: Sim: Fix that some callsigns could mess up emesary communications. (#164)
+ 2022-07-17  F-15: emexec changes to aircraft-main
+ 2022-07-17  F-15: TEWS improvements
+ 2022-07-17  F-15: VSD improvemets
+ 2022-07-17  F-15: change to use emexec
+ 2022-07-17  F-15: Use new Emesary Exec module (emexec)
+ 2022-07-15  F-15: Fix VSD on backseat
+ 2022-07-10  F-15: weapons update (#162)
+ 2022-02-06  F-15: MPCD SIT readability
+ 2022-02-06  F-15: Updated damage files
+ 2022-01-22  F-15: Fix target lock over MP
+ 2022-01-20  F-15: Fixes #151 : New SIT display on MPCD
+ 2021-08-16  F-15: 2018.3 compatibility
+ 2021-08-16  F-15: Fix JFS hyds
+ 2021-08-16  F-15: fix JSBSim property initialization warnings.
+ 2021-06-19  F-15: WIP Landing tutorial
+ 2021-05-27  F-15: MP animations and external stores
+ 2021-05-27  F-15: rework external stores select animations
+ 2021-05-27  F-15: prevent changing of stuff according to usual convention.
+ 2021-05-21  F-15: Forgot to commit this change to bomb weight.
+ 2021-05-21  F-15: Small change to sending spiked msg to locked aircraft.
+ 2021-05-20  F-15: Added failure mode for fire-control.
+ 2021-05-20  F-15: Added GBU-10 Paveway II laser guided bombs. Added bomb release sound.
+ 2021-05-20  F-15: Fix the ccippipper was rotating opposite.
+ 2021-05-20  F-15: Fix same bug
+ 2021-05-20  F-15: Fixed uncommmented line
+ 2021-05-20  F-15: Wing inboard station pylon/rack weight now again done in JSBSim.
+ 2021-05-15  F-15: Added training configuration (#83)
+ 2021-05-15  F-15: Added Training option (#84)
+ 2021-01-28  F-15: Remove JMaverick16 personal liveries;
+ 2021-01-28  F-15: remove userarchive from model properties.
+ 2020-10-26  F-15: Use PartitionProcessor from core libs
+ 2020-10-09  F-15: HUD fix IAS speed tape
+ 2020-09-29  F-15: Revert changes to MPCD (incorrect model saved)
+ 2020-09-03  F-15: Emesary fixes
+ 2020-09-03  F-15: Added missing aero reference
+ 2020-10-15  F-15: Adding more missiles
+ 2020-09-29  F-15: Revert changes to MPCD (incorrect model saved)
+ 2020-09-03  F-15: Emesary fixes
+ 2020-09-03  F-15: Added missing aero reference
+ 2020-03-26  F-15: Tuning of flaps
+ 2020-02-23  F-15: UV map fixes
+ 2019-12-21  F-15: latest livery version
+ 2019-11-02  F-15: Contrail now depends on weather rather than altitude


