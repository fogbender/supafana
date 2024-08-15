import { GiDragonSpiral as Dragon } from "react-icons/gi";

const SectionHeader = ({
  text,
  children = null,
}: {
  text: string;
  children?: null | JSX.Element;
}) => {
  return (
    <div className="flex items-center gap-3 font-medium text-xl">
      <Dragon size={32} />
      <div className="flex flex-col">
        <span>{text}</span>
        {children}
      </div>
    </div>
  );
};

export default SectionHeader;
