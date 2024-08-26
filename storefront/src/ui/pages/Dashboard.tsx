import { DashboardWithProviders } from "../Dashboard";
import { RequireAuth } from "../RequireAuth";

export const DashboardPage = () => {
  return (
    <RequireAuth>
      <DashboardWithProviders />
    </RequireAuth>
  );
};
