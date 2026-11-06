{
  budget = {
    maxGenerations = 3;
    maxSpawns = 12;
  };
  check = {
    contract = [
      {
        options = [{label = "pass";} {label = "fail";}];
        prompt = "Verdict?";
      }
      {prompt = "Strongest concrete improvement.";}
    ];
    passValue = "pass";
    system_prompt = "Judge the candidate artifact against the goal strictly on the evidence shown. Return the verdict option values.";
    use = "panel";
  };
  converge = {quorum = 1;};
  doer = {
    contract = [{prompt = "Summarize the artifact you produced, how it meets the goal, and its verification.";}];
    system_prompt = "You are a careful implementer. Produce the best artifact for the goal, then summarize what you produced, how it meets the goal, and how you verified it.";
  };
  goal = "PLACEHOLDER: replace with the concrete objective for this run. This string is included in every doer task.";
  strategy = {
    population = 1;
    survivors = 1;
  };
}
