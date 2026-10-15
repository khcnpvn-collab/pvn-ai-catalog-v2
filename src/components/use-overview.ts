"use client";
import { useEffect, useState } from "react";
import type { Overview } from "@/lib/overview";
import { api } from "./ui";

// One shared request for every dashboard and dossier section on screen; edits invalidate it.
let cached: { at: number; promise: Promise<Overview> } | null = null;
const listeners = new Set<() => void>();
const MAX_AGE = 30_000;

function load(): Promise<Overview> {
  if (!cached || Date.now() - cached.at > MAX_AGE) {
    const promise = api<{ data: Overview }>("/api/overview").then(result => result.data);
    cached = { at: Date.now(), promise };
    promise.catch(() => { if (cached?.promise === promise) cached = null; });
  }
  return cached.promise;
}

export function invalidateOverview() {
  cached = null;
  listeners.forEach(listener => listener());
}

export function useOverview() {
  const [revision, setRevision] = useState(0);
  const [state, setState] = useState<{ revision: number; data?: Overview; error?: Error }>({ revision: -1 });
  useEffect(() => {
    const listener = () => setRevision(value => value + 1);
    listeners.add(listener);
    return () => { listeners.delete(listener); };
  }, []);
  useEffect(() => {
    let active = true;
    load().then(data => { if (active) setState({ revision, data }); }).catch(error => { if (active) setState({ revision, error }); });
    return () => { active = false; };
  }, [revision]);
  return { data: state.data, error: state.revision === revision ? state.error : undefined, loading: state.revision !== revision && !state.data, refresh: invalidateOverview };
}
