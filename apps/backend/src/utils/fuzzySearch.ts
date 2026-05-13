
/**
 * Computes the Levenshtein distance between two strings.
 * Used for fuzzy duplicate detection.
 */
export const getLevenshteinDistance = (s: string, t: string): number => {
    if (s === t) return 0;
    if (s.length === 0) return t.length;
    if (t.length === 0) return s.length;

    const v0 = new Array(t.length + 1);
    const v1 = new Array(t.length + 1);

    for (let i = 0; i <= t.length; i++) v0[i] = i;

    for (let i = 0; i < s.length; i++) {
        v1[0] = i + 1;
        for (let j = 0; j < t.length; j++) {
            const cost = s[i] === t[j] ? 0 : 1;
            v1[j + 1] = Math.min(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
        }
        for (let j = 0; j <= t.length; j++) v0[j] = v1[j];
    }
    return v0[t.length];
};

/**
 * Normalizes a string for comparison: lowercase, trim, remove double spaces.
 */
export const normalizeName = (name: string): string => {
    return name.toLowerCase().trim().replace(/\s+/g, ' ');
};

/**
 * Checks if a name is likely a duplicate of an existing list.
 * Returns the match if found.
 */
export const findSimilarMatch = (candidate: string, existing: string[], threshold = 2): string | null => {
    const normalizedCandidate = normalizeName(candidate);
    for (const entry of existing) {
        const normalizedEntry = normalizeName(entry);
        if (normalizedEntry === normalizedCandidate) return entry;
        
        const distance = getLevenshteinDistance(normalizedCandidate, normalizedEntry);
        if (distance <= threshold) return entry;
    }
    return null;
};
