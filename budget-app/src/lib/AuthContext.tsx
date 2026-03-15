import React, { createContext, useContext, useEffect, useState, useRef } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from './supabase';
import { useStore } from '../store/useStore';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signUp: (email: string, password: string) => Promise<{ error: Error | null }>;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signInWithGoogle: () => Promise<{ error: Error | null }>;
  signInWithApple: () => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const loadedUserRef = useRef<string | null>(null);

  useEffect(() => {
    let subscription: { unsubscribe: () => void } | null = null;

    const init = async () => {
      try {
        // Get initial session
        const { data: { session } } = await supabase.auth.getSession();
        setSession(session);
        const currentUser = session?.user ?? null;
        setUser(currentUser);

        // Load user data from Supabase on initial session
        if (currentUser && loadedUserRef.current !== currentUser.id) {
          loadedUserRef.current = currentUser.id;
          await useStore.getState().loadFromDatabase(currentUser.id);
        }
      } catch (err) {
        console.error('[Auth] Failed to get session:', err);
      } finally {
        setLoading(false);
      }
    };

    // Timeout fallback in case init hangs
    const timeout = setTimeout(() => {
      console.warn('[Auth] Session check timed out');
      setLoading(false);
    }, 5000);

    init().then(() => clearTimeout(timeout));

    // Listen for auth changes
    try {
      const { data } = supabase.auth.onAuthStateChange(async (_event, session) => {
        setSession(session);
        const currentUser = session?.user ?? null;
        setUser(currentUser);

        if (currentUser && loadedUserRef.current !== currentUser.id) {
          loadedUserRef.current = currentUser.id;
          await useStore.getState().loadFromDatabase(currentUser.id);
        } else if (!currentUser && loadedUserRef.current) {
          loadedUserRef.current = null;
          useStore.getState().clearData();
        }

        setLoading(false);
      });
      subscription = data.subscription;
    } catch (err) {
      console.error('[Auth] onAuthStateChange failed:', err);
    }

    return () => subscription?.unsubscribe();
  }, []);

  const signUp = async (email: string, password: string) => {
    const { error } = await supabase.auth.signUp({
      email,
      password,
    });
    return { error: error as Error | null };
  };

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    return { error: error as Error | null };
  };

  const signInWithGoogle = async () => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: window.location.origin,
      },
    });
    return { error: error as Error | null };
  };

  const signInWithApple = async () => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'apple',
      options: {
        redirectTo: window.location.origin,
      },
    });
    return { error: error as Error | null };
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    useStore.getState().clearData();
    loadedUserRef.current = null;
  };

  return (
    <AuthContext.Provider value={{ user, session, loading, signUp, signIn, signInWithGoogle, signInWithApple, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
