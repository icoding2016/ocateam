# Project target
This project is to experiment defining and using multi-agent for long-run agentic project 
(end to end requirement analysis - design - implment/test/debug - quality gating).

With multi-agents role definition and workflow orchistrating, the coding agent can apply the pre-defined multi-agent co-work pattern to run a project. 

the code repo will contain the agent definitions and workflow file(s).


# Tech point

## Define agents for the agentic worflow:

Multiple agents work in a 'Leader + workers' pattern

The agents:
- orchistrator: the lead agent that organize the end-to-end activity. Make sure the project moving forwarded as planned/expected. 
    incl. 
    communicate with user (requirement understanding, clarification, confirmation, etc)
    planning, tasks definition/decomposition, 
    organize activities (trigger/spawn agent for specific task, check progress and reveiw agent output),  
    control/gating project progress.
- architect: system architect, design, deep analyse.  (No coding/testing)
- developer: the one doing implementation. developiong/testing/debugging. 
- reviewer:  skeptical reviewer for all types/stages of output/delivery (specificiation, design, implenetation, test coverage/result, etc)
    with system-level view and project-success/user-satisfactory perspective & mindset, 
    a master of quality-assurance 
- explorer:  a quick actioner for simple/small tasks (e.g info searching/collecting, code/repo insepction), an assistant to support the main/complicate tasks so the main tasks can stay focused. 

## Project/workflow Control
- The orchistrator controls and organizes the E2E workflow, plans and tracks the stages/tasks, spawns and coordicates the 'worker' agents.
- Dedicated goal/requirement understanding stage before implementation. 
- Plan/actions tracks with documents (document is the main way for cross-agent coordination)
- For each project stage/phase, implementation/refine loop is controlled by the orchistrator with the reviewer gating the output quality. 
  for each review, the reviewer not only check if the output match the planned task goal, but also check if current stage match the project goal, in-line with the original custom requirement/key-concerns.
  running in "implement/refine->review" cycle



# tools/setup

The Agent tool need to support multi-agents.
The tool to use in this experiment is opencode (current version 1.17.13 support multi-agent).

there are existing opensource projects/repos defining agent roles that can be references if suitable


# codebase
/Users/jerry.xie/code/icoding/multi-agent  is the codebase, 
other same level of dir/codebase are not relevent