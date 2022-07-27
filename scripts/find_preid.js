#!/usr/bin/env node

// - @recreateideas/entry: 0.2.0-develop.2
// - @recreateideas/pkg-1: 0.3.0-develop.2
// - @recreateideas/pkg-2: 0.7.0-develop.5

const get = () => {
  const currentPreId = process.argv[2];
  const changed = process.argv[3];
  const remoteTags = process.argv[4].split(" ");
  // const currentBranch
  // console.log(changed);
  return changed;
};
console.log(get());
