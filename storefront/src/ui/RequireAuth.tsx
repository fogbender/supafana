import qs from "query-string";
import React from "react";
import { Navigate, useLocation } from "react-router";

export const RequireAuth: React.FC<{ children: JSX.Element }> = ({ children }) => {
  const needsLogin = false;
  const location = useLocation();

  if (needsLogin) {
    return (
      <Navigate
        to={{
          pathname: "/login",
          search: qs.stringify({
            redirectTo: window.location.href,
          }),
        }}
        state={{ from: location }}
      />
    );
  }

  return children;
};
