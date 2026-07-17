/** Shared by every weighted-random game outcome (wheel, scratch, ...). */
export function weightedPickIndex(weights: number[], rand: () => number = Math.random): number {
  const total = weights.reduce((sum, w) => sum + w, 0);
  let r = rand() * total;
  for (let i = 0; i < weights.length; i++) {
    if (r < weights[i]) return i;
    r -= weights[i];
  }
  return weights.length - 1;
}
