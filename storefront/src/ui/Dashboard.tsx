import browser from "browser-detect";
import classNames from "classnames";
import { Provider as JotaiProvider, useAtom } from "jotai";
import React from "react";
import { lazily } from "react-lazily";
import { QueryClientProvider, useMutation, useQuery } from "@tanstack/react-query";
import {
  Link,
  Navigate,
  Route,
  Routes,
  useLocation,
  useMatch,
  useNavigate,
  useParams,
  useSearchParams,
} from "react-router-dom";
import { Title } from "reactjs-meta";
import wretch from "wretch";
import { apiServer, queryClient, queryKeys } from "./client";

// import { getServerUrl } from "../config";

(JotaiProvider as any).displayName = "JotaiProvider";

export const Dashboard = () => {
  const navigate = useNavigate();

  return (
    <div>
      Supafana
    </div>
  );
};

export const DashboardWithProviders = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <JotaiProvider>
        <Dashboard />
      </JotaiProvider>
    </QueryClientProvider>
  );
};
