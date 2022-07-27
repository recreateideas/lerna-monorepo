#!/usr/bin/env node

// - @recreateideas/entry: 0.2.0-develop.2
// - @recreateideas/pkg-1: 0.3.0-develop.2
// - @recreateideas/pkg-2: 0.7.0-develop.5
const config = {
  branches: [
    {
      name: /.*/,
      label: "Feature",
    },
    {
      name: /^develop$/,
      label: "Develop",
    },
    {
      name: /^release$/,
      label: "Release",
    },
    {
      name: /^propd$/,
      label: "Production",
    },
  ],
};
const findPreidIndex = (preId) =>
  config.branches.findIndex((b) => new RegExp(b.name).test(preId));

const find_preid = () => {
  const destPreId = process.argv[2];
  const destIndex = findPreidIndex(destPreId);
  const changed = JSON.parse(process.argv[3]);
  changed.map((c) => {
    const [sourceVersion, sourceBaseVersion, sourcePreid] = new RegExp(
      "([0-9.]+)-(.*)(.[0-9])",
      "g"
    ).exec(c.version);
    const sourceIndex = findPreidIndex(sourcePreid);
    if (sourceIndex === destIndex) {
      console.log("DO NOTHING, SAME");
    } else if (sourceIndex > destIndex) {
      console.log("DO NOTHING, AHEAD");
    } else if (sourceIndex < destIndex) {
      console.log("BUMP");
    }
    // compare
    // update
    // commit
    console.log(sourceVersion);
  });
  const remoteTags = process.argv[4].split(" ");
  const branch = config.branches.find((b) =>
    new RegExp(b.name).test(destPreId)
  );
  console.log("Destination: ", branch.label);
  // console.log("Destination: ", branch.label);
  return "";
};
console.log(find_preid());
