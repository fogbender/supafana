import { Suspense } from "react";
import { lazily } from "react-lazily";
import { Route, BrowserRouter as Router, Routes } from "react-router-dom";

const { DashboardPage } = lazily(() => import("./pages/Dashboard"));
const { SupportPage } = lazily(() => import("./pages/Support"));
// const { Login } = lazily(() => import("./Login"));
// const { Signup } = lazily(() => import("./Signup"));
const { Landing } = lazily(() => import("./ReactLanding"));

const AppBody = () => {
  return (
    <Suspense fallback={null}>
      <>
        <Router>
          <Routes>
            <Route path="/" element={<Landing />} />
            {/*
            <Route path="login/*" element={<Login />} />
            <Route path="signup/*" element={<Signup />} />
            */}
            <Route path="support" element={<SupportPage />} />
            <Route path="dashboard/*" element={<DashboardPage />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </Router>
      </>
    </Suspense>
  );
};

export const NotFound = () => {
  return <div className="p-20 text-center text-6xl">404</div>;
};

export default AppBody;
